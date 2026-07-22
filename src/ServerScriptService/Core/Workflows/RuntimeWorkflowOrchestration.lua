--!strict

local Cancellation = require(script.Parent.WorkflowCancellation)
local Activation = require(script.Parent.WorkflowActivation)
local Causation = require(script.Parent.WorkflowCausation)
local Compensation = require(script.Parent.WorkflowCompensation)
local Completion = require(script.Parent.WorkflowCompletion)
local Correlation = require(script.Parent.WorkflowCorrelation)
local Diagnostics = require(script.Parent.WorkflowDiagnostics)
local Evidence = require(script.Parent.WorkflowEvidence)
local Pipeline = require(script.Parent.WorkflowExecutionPipeline)
local Instances = require(script.Parent.WorkflowInstances)
local Lifecycle = require(script.Parent.WorkflowLifecycle)
local Metrics = require(script.Parent.WorkflowMetrics)
local Profiler = require(script.Parent.WorkflowProfiler)
local Registry = require(script.Parent.WorkflowRegistry)
local Retries = require(script.Parent.WorkflowRetries)
local Resumption = require(script.Parent.WorkflowResumption)
local Routing = require(script.Parent.WorkflowRouting)
local Scheduler = require(script.Parent.WorkflowScheduler)
local SchedulerHardening = require(script.Parent.WorkflowSchedulerHardening)
local Serialization = require(script.Parent.WorkflowSerialization)
local Snapshots = require(script.Parent.WorkflowSnapshots)
local Suspension = require(script.Parent.WorkflowSuspension)
local Timeouts = require(script.Parent.WorkflowTimeouts)
local Transitions = require(script.Parent.WorkflowTransitions)
local Types = require(script.Parent.WorkflowTypes)
local Waits = require(script.Parent.WorkflowWaits)

local Runtime = {}
local shutdown = false
local counters = {
	registeredDefinitions = 0,
	createdInstances = 0,
	scheduledInstances = 0,
	runningInstances = 0,
	waitingInstances = 0,
	completedInstances = 0,
	cancelledInstances = 0,
	failedInstances = 0,
	activatedInstances = 0,
	routedMessages = 0,
	suspendedInstances = 0,
	resumedInstances = 0,
	validatedCompletions = 0,
	lastFailure = nil :: any?,
}

Runtime.Responsibilities = {
	"workflow definitions",
	"workflow registration",
	"workflow lifecycle",
	"workflow scheduling metadata",
	"workflow messaging integration metadata",
	"workflow correlation and causation metadata",
	"workflow activation, suspension, resumption, and completion validation metadata",
	"workflow evidence",
	"workflow diagnostics",
}

local function failure(code: string, message: string, payload: any?)
	counters.lastFailure =
		{ code = code, message = message, payload = Serialization.deepCopy(payload) }
	Metrics.increment("failures")
	Evidence.record("workflow failure", counters.lastFailure)
	return { ok = false, code = code, message = message }
end

local function registerCoreWorkflow()
	Registry.register({
		workflowId = Types.ProviderName .. ".self",
		version = "1",
		ownerRuntime = Types.ProviderName,
		category = Types.Category.System,
		entryState = "Ready",
		states = { "Ready", "Completed", "Cancelled", "Failed" },
		transitions = {
			{
				fromState = "Ready",
				toState = "Completed",
				source = Types.TransitionSource.CommandAcknowledged,
			},
		},
		timeouts = {},
		retryPolicy = { maxAttempts = 0, retryInterval = 0, terminalFailure = "Failed" },
		cancellationPolicy = { requiresAuthorization = true },
		completionPolicy = { terminalState = "Completed" },
	})
end

function Runtime.registerWorkflow(definition: any)
	if shutdown then
		return failure(Types.FailureType.ValidationFailure, "runtime is shut down", definition)
	end
	local result = Registry.register(definition)
	if not result.ok then
		return failure(result.code, result.message, definition)
	end
	counters.registeredDefinitions = Registry.count()
	return result
end

function Runtime.createInstance(request: any)
	if shutdown then
		return failure(Types.FailureType.ValidationFailure, "runtime is shut down", request)
	end
	local result = Instances.create(request)
	if not result.ok then
		return failure(result.code, result.message, request)
	end
	counters.createdInstances = Instances.count()
	Metrics.increment("workflowsStarted")
	return result
end

function Runtime.activateWorkflow(request: any, priority: number?, deadline: number?)
	if type(request) == "table" and Correlation.get(request.correlationId) ~= nil then
		return failure(Types.FailureType.DuplicateCorrelation, "duplicate correlation id", request)
	end
	local instanceResult = Runtime.createInstance(request)
	if not instanceResult.ok then
		return instanceResult
	end
	Pipeline.begin(request.instanceId)
	Pipeline.record(request.instanceId, Types.ExecutionStage.Validated, {
		workflowId = request.workflowId,
		correlationId = request.correlationId,
	})
	local correlation = Correlation.create({
		correlationId = request.correlationId,
		causationId = request.causationId,
		workflowId = request.workflowId,
		instanceId = request.instanceId,
		sourceKind = "Workflow",
		sourceId = request.requester,
		metadata = request.metadata,
	})
	if not correlation.ok then
		return failure(correlation.code, correlation.message, request)
	end
	Causation.record({
		causationId = request.causationId,
		correlationId = request.correlationId,
		instanceId = request.instanceId,
		messageKind = Types.MessageKind.CommandIntent,
		sourceRuntime = request.requester,
		targetRuntime = Types.ProviderName,
		metadata = request.metadata,
	})
	Activation.record(request.instanceId, request.correlationId, request.requester)
	Pipeline.record(request.instanceId, Types.ExecutionStage.Activated, {
		requester = request.requester,
	})
	counters.activatedInstances += 1
	local admission = SchedulerHardening.recordAdmission(request.instanceId, priority, deadline)
	if not admission.ok then
		return admission
	end
	return Runtime.schedule(request.instanceId, priority, deadline)
end

function Runtime.schedule(instanceId: string, priority: number?, deadline: number?)
	local lifecycle = Lifecycle.transition(instanceId, Types.LifecycleState.Validated)
	if not lifecycle.ok and lifecycle.code ~= Types.FailureType.InvalidLifecycleTransition then
		return lifecycle
	end
	local scheduled = Lifecycle.transition(instanceId, Types.LifecycleState.Scheduled)
	if not scheduled.ok then
		return scheduled
	end
	local result = Scheduler.schedule(instanceId, priority, deadline)
	if result.ok then
		counters.scheduledInstances += 1
	end
	return result
end

function Runtime.runNext()
	local scheduled = Scheduler.next()
	if scheduled == nil then
		return { ok = true, code = "Empty" }
	end
	local result = Lifecycle.transition(scheduled.instanceId, Types.LifecycleState.Running)
	if result.ok then
		counters.runningInstances += 1
	end
	return result
end

function Runtime.routeMessage(message: any)
	local routed = Routing.route(message)
	if not routed.ok then
		return failure(routed.code, routed.message, message)
	end
	Causation.record({
		causationId = message.causationId or message.messageId,
		parentCausationId = message.parentCausationId,
		correlationId = message.correlationId,
		instanceId = message.instanceId,
		messageKind = message.messageKind,
		sourceRuntime = message.sourceRuntime,
		targetRuntime = message.targetRuntime or Types.ProviderName,
		metadata = message.metadata or {},
	})
	Pipeline.record(message.instanceId, Types.ExecutionStage.MessageRouted, {
		messageId = message.messageId,
		messageKind = message.messageKind,
	})
	counters.routedMessages += 1
	return routed
end

function Runtime.transition(instanceId: string, source: string, variables: any?)
	local result = Transitions.apply(instanceId, source, variables)
	if result.ok then
		Profiler.recordTransition(instanceId, 0)
		Pipeline.record(instanceId, Types.ExecutionStage.Transitioned, {
			source = source,
		})
	end
	return result
end

function Runtime.waitFor(instanceId: string, waitKind: string, target: string, timeoutAt: number?)
	local wait = Waits.add(instanceId, waitKind, target, timeoutAt)
	if not wait.ok then
		return wait
	end
	local lifecycle = Lifecycle.transition(instanceId, Types.LifecycleState.Waiting)
	if lifecycle.ok then
		counters.waitingInstances += 1
	end
	return lifecycle
end

function Runtime.suspendWorkflow(
	instanceId: string,
	waitKind: string,
	target: string,
	timeoutAt: number?
)
	local result = Runtime.waitFor(instanceId, waitKind, target, timeoutAt)
	if result.ok then
		Suspension.record(instanceId, waitKind, target)
		Pipeline.record(instanceId, Types.ExecutionStage.Suspended, {
			waitKind = waitKind,
			target = target,
		})
		counters.suspendedInstances += 1
	end
	return result
end

function Runtime.resumeWorkflow(message: any)
	local routed = Runtime.routeMessage(message)
	if not routed.ok then
		return routed
	end
	local lifecycle = Lifecycle.transition(message.instanceId, Types.LifecycleState.Running)
	if lifecycle.ok then
		Resumption.record(message.instanceId, message.messageId)
		Pipeline.record(message.instanceId, Types.ExecutionStage.Resumed, {
			messageId = message.messageId,
		})
		counters.resumedInstances += 1
	end
	return lifecycle
end

function Runtime.recordTimeout(instanceId: string, waitState: string, timeoutTransition: string)
	Metrics.increment("timeoutCount")
	return Timeouts.record(instanceId, waitState, timeoutTransition)
end

function Runtime.recordRetry(
	instanceId: string,
	reason: string,
	attempt: number,
	maxAttempts: number
)
	Metrics.increment("retryCount")
	return Retries.record(instanceId, reason, attempt, maxAttempts)
end

function Runtime.cancel(instanceId: string, authorized: boolean, reason: string)
	local result = Cancellation.cancel(instanceId, authorized, reason)
	if result.ok then
		counters.cancelledInstances += 1
		Metrics.increment("cancellationCount")
	end
	return result
end

function Runtime.complete(instanceId: string)
	local lifecycle = Lifecycle.transition(instanceId, Types.LifecycleState.Completed)
	if not lifecycle.ok then
		return lifecycle
	end
	local result = Instances.complete(instanceId, Types.LifecycleState.Completed)
	if result.ok then
		counters.completedInstances += 1
		Metrics.increment("workflowsCompleted")
		Pipeline.finish(instanceId)
		local instance = Instances.get(instanceId)
		if instance ~= nil then
			Profiler.recordWorkflow(instanceId, instance.workflowId, 0)
		end
	end
	return result
end

function Runtime.validateCompletion(instanceId: string)
	local result = Completion.validate(instanceId)
	if result.ok then
		Pipeline.record(instanceId, Types.ExecutionStage.CompletionValidated, {
			complete = result.completion.complete,
		})
		counters.validatedCompletions += 1
	end
	return result
end

function Runtime.planCompensation(instanceId: string, commandType: string, reason: string)
	Pipeline.record(instanceId, Types.ExecutionStage.CommandIssued, {
		commandType = commandType,
		reason = reason,
	})
	return Compensation.plan(instanceId, commandType, reason)
end

function Runtime.inspect()
	return Diagnostics.capture(Runtime)
end

function Runtime.getSnapshot()
	return Snapshots.capture(Runtime)
end

function Runtime.validate(): (boolean, string?)
	return true, nil
end

function Runtime.shutdown()
	shutdown = true
end

function Runtime.reset()
	shutdown = false
	for key in pairs(counters) do
		if key == "lastFailure" then
			counters[key] = nil
		else
			counters[key] = 0
		end
	end
	Registry.clear()
	Instances.clear()
	Lifecycle.clear()
	Scheduler.clear()
	Waits.clear()
	Timeouts.clear()
	Retries.clear()
	Compensation.clear()
	Correlation.clear()
	Causation.clear()
	Routing.clear()
	Pipeline.clear()
	Activation.clear()
	Suspension.clear()
	Resumption.clear()
	Completion.clear()
	SchedulerHardening.clear()
	Evidence.clear()
	Metrics.clear()
	Profiler.clear()
	registerCoreWorkflow()
	counters.registeredDefinitions = Registry.count()
end

function Runtime.isShutdown(): boolean
	return shutdown
end

function Runtime.getDefinitions()
	return Registry.inspect()
end

function Runtime.getInstances()
	return Instances.inspect()
end

function Runtime.getCounters()
	return Serialization.deepCopy(counters)
end

function Runtime.getIntegration()
	return Serialization.deepCopy({
		correlationRecords = Correlation.inspect(),
		causationRecords = Causation.inspect(),
		routingRecords = Routing.inspect(),
		executionPipeline = Pipeline.inspect(),
		activationRecords = Activation.inspect(),
		suspensionRecords = Suspension.inspect(),
		resumptionRecords = Resumption.inspect(),
		completionRecords = Completion.inspect(),
		schedulerHardening = SchedulerHardening.inspect(),
	})
end

Runtime.reset()

return Runtime

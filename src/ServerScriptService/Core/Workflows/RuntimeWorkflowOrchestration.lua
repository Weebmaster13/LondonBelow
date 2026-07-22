--!strict

local Cancellation = require(script.Parent.WorkflowCancellation)
local Compensation = require(script.Parent.WorkflowCompensation)
local Diagnostics = require(script.Parent.WorkflowDiagnostics)
local Evidence = require(script.Parent.WorkflowEvidence)
local Instances = require(script.Parent.WorkflowInstances)
local Lifecycle = require(script.Parent.WorkflowLifecycle)
local Metrics = require(script.Parent.WorkflowMetrics)
local Profiler = require(script.Parent.WorkflowProfiler)
local Registry = require(script.Parent.WorkflowRegistry)
local Retries = require(script.Parent.WorkflowRetries)
local Scheduler = require(script.Parent.WorkflowScheduler)
local Serialization = require(script.Parent.WorkflowSerialization)
local Snapshots = require(script.Parent.WorkflowSnapshots)
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
	lastFailure = nil :: any?,
}

Runtime.Responsibilities = {
	"workflow definitions",
	"workflow registration",
	"workflow lifecycle",
	"workflow scheduling metadata",
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

function Runtime.transition(instanceId: string, source: string, variables: any?)
	local result = Transitions.apply(instanceId, source, variables)
	if result.ok then
		Profiler.recordTransition(instanceId, 0)
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
		local instance = Instances.get(instanceId)
		if instance ~= nil then
			Profiler.recordWorkflow(instanceId, instance.workflowId, 0)
		end
	end
	return result
end

function Runtime.planCompensation(instanceId: string, commandType: string, reason: string)
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

Runtime.reset()

return Runtime

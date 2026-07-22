--!strict

local Diagnostics = require(script.Parent.InteractionDiagnostics)
local Evidence = require(script.Parent.InteractionEvidence)
local Interruption = require(script.Parent.DialogueInterruptionManager)
local Manager = require(script.Parent.InteractionRequestManager)
local Metrics = require(script.Parent.InteractionMetrics)
local Nested = require(script.Parent.NestedConversationManager)
local PendingQueue = require(script.Parent.PendingChoiceQueue)
local Profiler = require(script.Parent.InteractionProfiler)
local Registry = require(script.Parent.InteractionSessionRegistry)
local RuntimeEvents = require(script.Parent.RuntimeEventCoordinator)
local Serialization = require(script.Parent.DialogueSerialization)
local Snapshots = require(script.Parent.InteractionSnapshots)
local TimeoutManager = require(script.Parent.InteractionTimeoutManager)
local Types = require(script.Parent.DialogueInteractionTypes)
local Validation = require(script.Parent.InteractionValidation)

local Runtime = {}
local shutdown = false
local counters = {
	interactionsCreated = 0,
	responsesProcessed = 0,
	cancelled = 0,
	expired = 0,
	interrupted = 0,
	resumed = 0,
	nestedEntered = 0,
	nestedExited = 0,
	coordinationStatus = "Stopped",
	lastFailure = nil :: any?,
}

local function fail(code: string, message: string, payload: any?)
	counters.lastFailure =
		{ code = code, message = message, payload = Serialization.deepCopy(payload) }
	Evidence.record("interaction failure", counters.lastFailure)
	return { ok = false, code = code, message = message }
end

function Runtime.requestInteraction(request: any)
	if shutdown then
		return fail(Types.FailureType.RuntimeShutdown, "runtime is shut down", request)
	end
	local result = Manager.requestInteraction(request)
	if not result.ok then
		return fail(result.code, result.message, request)
	end
	RuntimeEvents.enqueue(Types.RuntimeEventKind.InteractionCreated, request.executionId, {
		interactionId = request.interactionId,
	})
	RuntimeEvents.enqueue(Types.RuntimeEventKind.InteractionWaiting, request.executionId, {
		interactionId = request.interactionId,
	})
	counters.interactionsCreated += 1
	counters.coordinationStatus = "Waiting"
	Profiler.record(request.interactionId, "interactionLatency", 0)
	return result
end

function Runtime.submitResponse(interactionId: string, response: any)
	local session = Registry.get(interactionId)
	local result = Manager.submitResponse(interactionId, response)
	if not result.ok then
		return fail(
			result.code,
			result.message,
			{ interactionId = interactionId, response = response }
		)
	end
	counters.responsesProcessed += 1
	Metrics.increment("responsesProcessed")
	Profiler.record(interactionId, "validationLatency", 0)
	RuntimeEvents.enqueue(
		Types.RuntimeEventKind.InteractionValidated,
		session.executionId,
		{ interactionId = interactionId }
	)
	RuntimeEvents.enqueue(
		Types.RuntimeEventKind.InteractionApplied,
		session.executionId,
		{ interactionId = interactionId }
	)
	RuntimeEvents.enqueue(
		Types.RuntimeEventKind.InteractionResumed,
		session.executionId,
		{ interactionId = interactionId }
	)
	counters.coordinationStatus = "ResponseApplied"
	return result
end

function Runtime.cancelInteraction(interactionId: string, reason: string)
	local result = Manager.cancel(interactionId, reason)
	if not result.ok then
		return fail(result.code, result.message, { interactionId = interactionId })
	end
	counters.cancelled += 1
	return result
end

function Runtime.expireInteraction(interactionId: string, reason: string)
	local result = TimeoutManager.expire(interactionId, reason)
	if not result.ok then
		return fail(result.code, result.message, { interactionId = interactionId })
	end
	counters.expired += 1
	return result
end

function Runtime.interruptExecution(executionId: string, reason: string, priority: number)
	local result = Interruption.interrupt(executionId, reason, priority)
	if not result.ok then
		return fail(result.code, result.message, { executionId = executionId })
	end
	counters.interrupted += 1
	return result
end

function Runtime.resumeExecution(executionId: string)
	local result = Interruption.resume(executionId)
	if not result.ok then
		return fail(result.code, result.message, { executionId = executionId })
	end
	counters.resumed += 1
	Profiler.record(executionId, "resumeLatency", 0)
	return result
end

function Runtime.enterNestedConversation(
	parentExecutionId: string,
	childExecutionId: string,
	returnTarget: string,
	depth: number
)
	local result = Nested.enter(parentExecutionId, childExecutionId, returnTarget, depth)
	if not result.ok then
		return fail(
			result.code,
			result.message,
			{ parentExecutionId = parentExecutionId, childExecutionId = childExecutionId }
		)
	end
	counters.nestedEntered += 1
	return result
end

function Runtime.exitNestedConversation(childExecutionId: string)
	local result = Nested.exit(childExecutionId)
	if not result.ok then
		return fail(result.code, result.message, { childExecutionId = childExecutionId })
	end
	counters.nestedExited += 1
	return result
end

function Runtime.inspect()
	return Diagnostics.capture(Runtime)
end

function Runtime.getSnapshot()
	return Snapshots.capture(Runtime)
end

function Runtime.validate(): (boolean, string?)
	return Validation.validateRuntime()
end

function Runtime.shutdown()
	shutdown = true
	counters.coordinationStatus = "Shutdown"
end

function Runtime.reset()
	shutdown = false
	for key in pairs(counters) do
		if key == "lastFailure" then
			counters[key] = nil
		elseif key == "coordinationStatus" then
			counters[key] = "Stopped"
		else
			counters[key] = 0
		end
	end
	Evidence.clear()
	Interruption.clear()
	Metrics.clear()
	Nested.clear()
	PendingQueue.clear()
	Profiler.clear()
	Registry.clear()
	RuntimeEvents.clear()
	TimeoutManager.clear()
end

function Runtime.getCounters()
	return Serialization.deepCopy(counters)
end

Runtime.reset()

return Runtime

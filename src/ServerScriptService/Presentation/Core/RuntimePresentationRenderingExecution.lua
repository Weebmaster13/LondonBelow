--!strict

local Acknowledgements = require(script.Parent.RenderingExecutionAcknowledgements)
local Diagnostics = require(script.Parent.RenderingExecutionDiagnostics)
local Evidence = require(script.Parent.RenderingExecutionEvidence)
local Lifecycle = require(script.Parent.RenderingExecutionLifecycle)
local Metrics = require(script.Parent.RenderingExecutionMetrics)
local Profiler = require(script.Parent.RenderingExecutionProfiler)
local Queue = require(script.Parent.RenderingExecutionQueue)
local Recovery = require(script.Parent.RenderingExecutionRecovery)
local RendererExecutions = require(script.Parent.RendererExecutionRegistry)
local Scheduler = require(script.Parent.RenderingExecutionScheduler)
local Serialization = require(script.Parent.PresentationSerialization)
local Sessions = require(script.Parent.RenderingExecutionSessionRegistry)
local Snapshots = require(script.Parent.RenderingExecutionSnapshots)
local Synchronization = require(script.Parent.RenderingExecutionSynchronization)
local Types = require(script.Parent.PresentationTypes)
local Validation = require(script.Parent.RenderingExecutionValidation)

local Runtime = {}
local shutdown = false
local counters = {
	executionSessionsCreated = 0,
	scheduledExecutions = 0,
	startedExecutions = 0,
	failures = 0,
	lastFailure = nil :: any?,
}
local failures = {}

local function fail(code: string, message: string, payload: any?)
	counters.failures += 1
	counters.lastFailure =
		{ code = code, message = message, payload = Serialization.diagnosticCopy(payload or {}) }
	failures[#failures + 1] = counters.lastFailure
	Metrics.increment("validationFailures")
	Evidence.record("execution failure", counters.lastFailure)
	return { ok = false, code = code, message = message }
end

function Runtime.createExecutionSession(input: any)
	if shutdown then
		return fail(
			Types.RenderingExecutionFailureType.RuntimeShutdown,
			"runtime is shut down",
			input
		)
	end
	local result = Sessions.create(input)
	if not result.ok then
		return fail(result.code, result.message, input)
	end
	counters.executionSessionsCreated += 1
	Profiler.record(result.session.renderingExecutionSessionId, "executionLatency", 0)
	return result
end

function Runtime.enqueueExecution(sessionId: string)
	local result = Queue.enqueue(sessionId)
	if not result.ok then
		return fail(result.code, result.message, { renderingExecutionSessionId = sessionId })
	end
	Profiler.record(sessionId, "queueLatency", 0)
	return result
end

function Runtime.scheduleNext()
	local result = Scheduler.scheduleNext()
	if not result.ok then
		return fail(result.code, result.message, {})
	end
	if result.code == "Ok" then
		counters.scheduledExecutions += 1
	end
	Profiler.record(result.renderingExecutionSessionId or "empty", "schedulingDuration", 0)
	return result
end

function Runtime.execute(sessionId: string)
	local result = Scheduler.execute(sessionId)
	if not result.ok then
		return fail(result.code, result.message, { renderingExecutionSessionId = sessionId })
	end
	counters.startedExecutions += 1
	return result
end

function Runtime.suspend(sessionId: string)
	local result = Queue.suspend(sessionId)
	if not result.ok then
		return fail(result.code, result.message, { renderingExecutionSessionId = sessionId })
	end
	return result
end

function Runtime.resume(sessionId: string)
	local result = Queue.resume(sessionId)
	if not result.ok then
		return fail(result.code, result.message, { renderingExecutionSessionId = sessionId })
	end
	return result
end

function Runtime.cancel(sessionId: string, reason: string)
	local result = Lifecycle.transition(sessionId, Types.RenderingExecutionState.Cancelled)
	if not result.ok then
		return fail(
			result.code,
			result.message,
			{ renderingExecutionSessionId = sessionId, reason = reason }
		)
	end
	Evidence.record(
		"execution cancelled",
		{ renderingExecutionSessionId = sessionId, reason = reason }
	)
	return result
end

function Runtime.expire(sessionId: string, reason: string)
	local result = Lifecycle.transition(sessionId, Types.RenderingExecutionState.Expired)
	if not result.ok then
		return fail(
			result.code,
			result.message,
			{ renderingExecutionSessionId = sessionId, reason = reason }
		)
	end
	Evidence.record(
		"execution expired",
		{ renderingExecutionSessionId = sessionId, reason = reason }
	)
	return result
end

function Runtime.receiveAcknowledgement(input: any)
	if shutdown then
		return fail(
			Types.RenderingExecutionFailureType.RuntimeShutdown,
			"runtime is shut down",
			input
		)
	end
	local result = Acknowledgements.receive(input)
	if not result.ok then
		return fail(result.code, result.message, input)
	end
	Profiler.record(input.renderingExecutionSessionId, "acknowledgementLatency", 0)
	return result
end

function Runtime.complete(sessionId: string)
	local result = Lifecycle.transition(sessionId, Types.RenderingExecutionState.Completed)
	if not result.ok then
		return fail(result.code, result.message, { renderingExecutionSessionId = sessionId })
	end
	local session = Sessions.get(sessionId)
	if session ~= nil then
		RendererExecutions.complete(session.rendererId, sessionId)
	end
	return result
end

function Runtime.resolveSynchronization(sessionId: string)
	local result = Synchronization.resolve(sessionId)
	if not result.ok then
		return fail(result.code, result.message, { renderingExecutionSessionId = sessionId })
	end
	Profiler.record(sessionId, "synchronizationLatency", 0)
	return result
end

function Runtime.recover()
	return Recovery.recover()
end

function Runtime.inspect()
	return Diagnostics.capture(Runtime)
end

function Runtime.getSnapshot()
	return Snapshots.capture(Runtime)
end

function Runtime.validate(): (boolean, string?)
	return Validation.validate()
end

function Runtime.shutdown()
	shutdown = true
	Scheduler.shutdown()
	Evidence.record("runtime shutdown", {})
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
	table.clear(failures)
	Acknowledgements.clear()
	Evidence.clear()
	Metrics.clear()
	Profiler.clear()
	Queue.clear()
	RendererExecutions.clear()
	Scheduler.clear()
	Sessions.clear()
	Synchronization.clear()
	Evidence.record("runtime reset", {})
end

function Runtime.getCounters()
	return Serialization.deepCopy(counters)
end

function Runtime.getFailures()
	return Serialization.deepCopy(failures)
end

Runtime.reset()

return Runtime

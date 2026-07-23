--!strict

local Acknowledgements = require(script.Parent.AcknowledgementExecutionEngine)
local Diagnostics = require(script.Parent.PresentationExecutionDiagnostics)
local Evidence = require(script.Parent.PresentationExecutionEvidence)
local Lifecycle = require(script.Parent.LifecycleExecutionEngine)
local Metrics = require(script.Parent.PresentationExecutionMetrics)
local Profiler = require(script.Parent.PresentationExecutionProfiler)
local Queue = require(script.Parent.PresentationExecutionQueue)
local Recovery = require(script.Parent.PresentationExecutionRecovery)
local Scheduler = require(script.Parent.PresentationExecutionScheduler)
local Serialization = require(script.Parent.PresentationSerialization)
local Sessions = require(script.Parent.SessionExecutionEngine)
local Snapshots = require(script.Parent.PresentationExecutionSnapshots)
local Synchronization = require(script.Parent.SynchronizationExecutionEngine)
local Types = require(script.Parent.PresentationTypes)
local Validation = require(script.Parent.PresentationExecutionValidation)

local Runtime = {}
local shutdown = false
local counters = {
	executionsCreated = 0,
	executionsStarted = 0,
	executionsCancelled = 0,
	executionsExpired = 0,
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

function Runtime.createExecution(request: any)
	if shutdown then
		return fail(Types.ExecutionFailureType.RuntimeShutdown, "runtime is shut down", request)
	end
	local result = Sessions.create(request)
	if not result.ok then
		return fail(result.code, result.message, request)
	end
	counters.executionsCreated += 1
	Profiler.record(result.execution.executionSessionId, "executionLatency", 0)
	return result
end

function Runtime.enqueueExecution(executionId: string)
	local result = Queue.enqueue(executionId)
	if not result.ok then
		return fail(result.code, result.message, { executionId = executionId })
	end
	Profiler.record(executionId, "queueLatency", 0)
	return result
end

function Runtime.scheduleNext()
	local result = Scheduler.scheduleNext()
	if not result.ok then
		return fail(result.code, result.message, {})
	end
	return result
end

function Runtime.execute(executionId: string)
	local result = Queue.execute(executionId)
	if not result.ok then
		return fail(result.code, result.message, { executionId = executionId })
	end
	counters.executionsStarted += 1
	Evidence.record("execution started", { executionSessionId = executionId })
	return result
end

function Runtime.suspend(executionId: string)
	local result = Queue.suspend(executionId)
	if not result.ok then
		return fail(result.code, result.message, { executionId = executionId })
	end
	Evidence.record("execution suspended", { executionSessionId = executionId })
	return result
end

function Runtime.resume(executionId: string)
	local result = Queue.resume(executionId)
	if not result.ok then
		return fail(result.code, result.message, { executionId = executionId })
	end
	Evidence.record("execution resumed", { executionSessionId = executionId })
	return result
end

function Runtime.cancel(executionId: string, reason: string)
	local result = Queue.cancel(executionId)
	if not result.ok then
		return fail(result.code, result.message, { executionId = executionId, reason = reason })
	end
	counters.executionsCancelled += 1
	Evidence.record("execution cancelled", { executionSessionId = executionId, reason = reason })
	return result
end

function Runtime.expire(executionId: string, reason: string)
	local result = Queue.expire(executionId)
	if not result.ok then
		return fail(result.code, result.message, { executionId = executionId, reason = reason })
	end
	counters.executionsExpired += 1
	Evidence.record("execution expired", { executionSessionId = executionId, reason = reason })
	return result
end

function Runtime.produceAcknowledgement(request: any)
	local result = Acknowledgements.produce(request)
	if not result.ok then
		return fail(result.code, result.message, request)
	end
	Profiler.record(request.executionSessionId, "acknowledgementLatency", 0)
	return result
end

function Runtime.complete(executionId: string)
	local result = Lifecycle.transition(executionId, Types.ExecutionState.Completed)
	if not result.ok then
		return fail(result.code, result.message, { executionId = executionId })
	end
	return result
end

function Runtime.resolveSynchronization(executionId: string)
	local result = Synchronization.resolve(executionId)
	if not result.ok then
		return fail(result.code, result.message, { executionId = executionId })
	end
	Profiler.record(executionId, "synchronizationLatency", 0)
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

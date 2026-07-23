--!strict

local Diagnostics = require(script.Parent.RobloxRenderingSessionDiagnostics)
local Evidence = require(script.Parent.RobloxRenderingSessionEvidence)
local Lifecycle = require(script.Parent.RobloxRendererLifecycle)
local Mapper = require(script.Parent.RobloxExecutionSessionMapper)
local Metrics = require(script.Parent.RobloxRenderingSessionMetrics)
local Ownership = require(script.Parent.RobloxRendererOwnership)
local Profiler = require(script.Parent.RobloxRenderingSessionProfiler)
local Reservation = require(script.Parent.RobloxRendererReservation)
local Scheduling = require(script.Parent.RobloxRendererScheduling)
local Serialization = require(script.Parent.PresentationSerialization)
local Sessions = require(script.Parent.RobloxRenderingSessionRegistry)
local Snapshots = require(script.Parent.RobloxRenderingSessionSnapshots)
local Types = require(script.Parent.PresentationTypes)
local Validation = require(script.Parent.RobloxRenderingSessionValidation)

local Runtime = {}
local shutdown = false
local counters = {
	sessionsCreated = 0,
	mappingsCreated = 0,
	reservationsCreated = 0,
	scheduledSessions = 0,
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
	Metrics.increment("runtimeFailures")
	Evidence.record("runtime failure", counters.lastFailure)
	return { ok = false, code = code, message = message }
end

function Runtime.createSession(input: any)
	if shutdown then
		return fail(
			Types.RobloxRenderingSessionFailureType.RuntimeShutdown,
			"runtime is shut down",
			input
		)
	end
	local result = Sessions.create(input)
	if not result.ok then
		return fail(result.code, result.message, input)
	end
	counters.sessionsCreated += 1
	Profiler.record(result.session.robloxRenderingSessionId, "sessionCreationDuration", 0)
	return result
end

function Runtime.mapExecutionSession(sessionId: string)
	local result = Mapper.map(sessionId)
	if not result.ok then
		return fail(result.code, result.message, { robloxRenderingSessionId = sessionId })
	end
	counters.mappingsCreated += 1
	Profiler.record(sessionId, "mappingDuration", 0)
	return result
end

function Runtime.reserveRenderer(sessionId: string)
	local result = Reservation.reserve(sessionId)
	if not result.ok then
		return fail(result.code, result.message, { robloxRenderingSessionId = sessionId })
	end
	counters.reservationsCreated += 1
	Profiler.record(sessionId, "reservationDuration", 0)
	return result
end

function Runtime.queueSession(sessionId: string)
	local result = Scheduling.queue(sessionId)
	if not result.ok then
		return fail(result.code, result.message, { robloxRenderingSessionId = sessionId })
	end
	Profiler.record(sessionId, "queueDuration", 0)
	return result
end

function Runtime.scheduleNext()
	local result = Scheduling.scheduleNext()
	if not result.ok then
		return fail(result.code, result.message, {})
	end
	if result.code == "Ok" then
		counters.scheduledSessions += 1
		Profiler.record(result.robloxRenderingSessionId, "schedulingDuration", 0)
	end
	return result
end

function Runtime.waitForExecution(sessionId: string)
	local result = Scheduling.waitForExecution(sessionId)
	if not result.ok then
		return fail(result.code, result.message, { robloxRenderingSessionId = sessionId })
	end
	return result
end

function Runtime.releaseReservation(sessionId: string)
	local result = Reservation.release(sessionId)
	if not result.ok then
		return fail(result.code, result.message, { robloxRenderingSessionId = sessionId })
	end
	Profiler.record(sessionId, "releaseDuration", 0)
	return result
end

function Runtime.closeSession(sessionId: string)
	local result = Lifecycle.transition(sessionId, Types.RobloxRenderingSessionState.Closed)
	if not result.ok then
		return fail(result.code, result.message, { robloxRenderingSessionId = sessionId })
	end
	Metrics.decrement("activeRendererSessions")
	return result
end

function Runtime.cancelSession(sessionId: string)
	local result = Lifecycle.transition(sessionId, Types.RobloxRenderingSessionState.Cancelled)
	if not result.ok then
		return fail(result.code, result.message, { robloxRenderingSessionId = sessionId })
	end
	Metrics.decrement("activeRendererSessions")
	return result
end

function Runtime.expireSession(sessionId: string)
	local result = Lifecycle.transition(sessionId, Types.RobloxRenderingSessionState.Expired)
	if not result.ok then
		return fail(result.code, result.message, { robloxRenderingSessionId = sessionId })
	end
	Metrics.decrement("activeRendererSessions")
	return result
end

function Runtime.inspect()
	Profiler.record(Types.RobloxRenderingSessionProviderName, "diagnosticsLatency", 0)
	return Diagnostics.capture(Runtime)
end

function Runtime.getSnapshot()
	Profiler.record(Types.RobloxRenderingSessionProviderName, "snapshotLatency", 0)
	return Snapshots.capture(Runtime)
end

function Runtime.validate(): (boolean, string?)
	return Validation.validate()
end

function Runtime.shutdown()
	shutdown = true
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
	Evidence.clear()
	Mapper.clear()
	Metrics.clear()
	Ownership.clear()
	Profiler.clear()
	Reservation.clear()
	Scheduling.clear()
	Sessions.clear()
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

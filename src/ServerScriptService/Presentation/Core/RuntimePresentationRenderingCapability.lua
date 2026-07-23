--!strict

local Acknowledgements = require(script.Parent.RenderingAcknowledgementProducer)
local Assignments = require(script.Parent.RendererAssignmentManager)
local Diagnostics = require(script.Parent.RenderingRuntimeDiagnostics)
local Evidence = require(script.Parent.RenderingRuntimeEvidence)
local Intake = require(script.Parent.RenderingRequestIntake)
local Lifecycle = require(script.Parent.RenderingLifecycleManager)
local Metrics = require(script.Parent.RenderingRuntimeMetrics)
local Profiler = require(script.Parent.RenderingRuntimeProfiler)
local Renderers = require(script.Parent.RendererRuntimeRegistry)
local RuntimeCapability = require(script.Parent.RenderingRuntimeCapabilityRegistry)
local Serialization = require(script.Parent.PresentationSerialization)
local Sessions = require(script.Parent.RenderingSessionRegistry)
local Snapshots = require(script.Parent.RenderingRuntimeSnapshots)
local Synchronization = require(script.Parent.RenderingSynchronizationRuntime)
local Types = require(script.Parent.PresentationTypes)
local Validation = require(script.Parent.RenderingRuntimeValidation)

local Runtime = {}
local shutdown = false
local counters = {
	renderersRegistered = 0,
	sessionsCreated = 0,
	assignmentsCreated = 0,
	acknowledgementsProduced = 0,
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
	Evidence.record("validation failure", counters.lastFailure)
	return { ok = false, code = code, message = message }
end

function Runtime.registerDefaultRuntime()
	if shutdown then
		return fail(Types.RenderingRuntimeFailureType.RuntimeShutdown, "runtime is shut down", {})
	end
	local result = RuntimeCapability.registerDefault()
	if not result.ok then
		return fail(result.code, result.message, {})
	end
	return result
end

function Runtime.registerRenderer(renderer: any)
	if shutdown then
		return fail(
			Types.RenderingRuntimeFailureType.RuntimeShutdown,
			"runtime is shut down",
			renderer
		)
	end
	local result = Renderers.register(renderer)
	if not result.ok then
		return fail(result.code, result.message, renderer)
	end
	counters.renderersRegistered += 1
	return result
end

function Runtime.intakeRenderingRequest(request: any)
	if shutdown then
		return fail(
			Types.RenderingRuntimeFailureType.RuntimeShutdown,
			"runtime is shut down",
			request
		)
	end
	local valid = Intake.validate(request)
	if not valid.ok then
		return fail(valid.code, valid.message, request)
	end
	local result = Sessions.create(request)
	if not result.ok then
		return fail(result.code, result.message, request)
	end
	counters.sessionsCreated += 1
	Profiler.record(result.session.renderingSessionId, "requestIntakeLatency", 0)
	local validated = Lifecycle.transition(
		result.session.renderingSessionId,
		Types.RenderingRuntimeLifecycleState.Validated
	)
	if not validated.ok then
		return fail(validated.code, validated.message, request)
	end
	local pending = Lifecycle.transition(
		result.session.renderingSessionId,
		Types.RenderingRuntimeLifecycleState.PendingRenderer
	)
	if not pending.ok then
		return fail(pending.code, pending.message, request)
	end
	return result
end

function Runtime.assignRenderer(sessionId: string)
	local result = Assignments.assign(sessionId)
	if not result.ok then
		return fail(result.code, result.message, { renderingSessionId = sessionId })
	end
	local transitioned =
		Lifecycle.transition(sessionId, Types.RenderingRuntimeLifecycleState.Assigned)
	if not transitioned.ok then
		return fail(transitioned.code, transitioned.message, { renderingSessionId = sessionId })
	end
	counters.assignmentsCreated += 1
	Profiler.record(sessionId, "assignmentLatency", 0)
	return result
end

function Runtime.transitionLifecycle(sessionId: string, nextState: string)
	local result = Lifecycle.transition(sessionId, nextState)
	if not result.ok then
		return fail(
			result.code,
			result.message,
			{ renderingSessionId = sessionId, nextState = nextState }
		)
	end
	Profiler.record(sessionId, "lifecycleLatency", 0)
	return result
end

function Runtime.produceAcknowledgement(acknowledgement: any)
	if shutdown then
		return fail(
			Types.RenderingRuntimeFailureType.RuntimeShutdown,
			"runtime is shut down",
			acknowledgement
		)
	end
	local result = Acknowledgements.produce(acknowledgement)
	if not result.ok then
		return fail(result.code, result.message, acknowledgement)
	end
	counters.acknowledgementsProduced += 1
	Profiler.record(acknowledgement.renderingSessionId, "acknowledgementLatency", 0)
	return result
end

function Runtime.resolveSynchronization(sessionId: string)
	local result = Synchronization.resolve(sessionId)
	if not result.ok then
		return fail(result.code, result.message, { renderingSessionId = sessionId })
	end
	Profiler.record(sessionId, "synchronizationLatency", 0)
	return result
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
	Assignments.clear()
	Evidence.clear()
	Metrics.clear()
	Profiler.clear()
	Renderers.clear()
	RuntimeCapability.clear()
	Sessions.clear()
	Synchronization.clear()
	RuntimeCapability.registerDefault()
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

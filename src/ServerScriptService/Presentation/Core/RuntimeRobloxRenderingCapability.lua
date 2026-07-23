--!strict

local Capabilities = require(script.Parent.RobloxCapabilityRegistry)
local Diagnostics = require(script.Parent.RobloxRenderingDiagnostics)
local Evidence = require(script.Parent.RobloxRenderingEvidence)
local Metrics = require(script.Parent.RobloxRenderingMetrics)
local Negotiation = require(script.Parent.RobloxCapabilityNegotiation)
local Profiler = require(script.Parent.RobloxRenderingProfiler)
local Renderers = require(script.Parent.RobloxRendererRegistry)
local Serialization = require(script.Parent.PresentationSerialization)
local Snapshots = require(script.Parent.RobloxRenderingSnapshots)
local Types = require(script.Parent.PresentationTypes)
local Validation = require(script.Parent.RobloxRenderingValidation)

local Runtime = {}
local shutdown = false
local counters = {
	renderersRegistered = 0,
	capabilitiesRegistered = 0,
	negotiationsPerformed = 0,
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

function Runtime.registerRenderer(renderer: any)
	if shutdown then
		return fail(
			Types.RobloxRenderingFailureType.RuntimeShutdown,
			"runtime is shut down",
			renderer
		)
	end
	local result = Renderers.register(renderer)
	if not result.ok then
		return fail(result.code, result.message, renderer)
	end
	counters.renderersRegistered += 1
	Profiler.record(result.renderer.rendererId, "registrationDuration", 0)
	return result
end

function Runtime.registerCapability(capability: any)
	if shutdown then
		return fail(
			Types.RobloxRenderingFailureType.RuntimeShutdown,
			"runtime is shut down",
			capability
		)
	end
	local result = Capabilities.register(capability)
	if not result.ok then
		return fail(result.code, result.message, capability)
	end
	counters.capabilitiesRegistered += 1
	Profiler.record(result.capability.capabilityId, "registrationDuration", 0)
	return result
end

function Runtime.negotiateCompatibility(input: any)
	if shutdown then
		return fail(Types.RobloxRenderingFailureType.RuntimeShutdown, "runtime is shut down", input)
	end
	local result = Negotiation.negotiate(input)
	if not result.ok then
		Metrics.increment("failedNegotiations")
		return fail(result.code, result.message, input)
	end
	counters.negotiationsPerformed += 1
	return result
end

function Runtime.inspect()
	Profiler.record(Types.RobloxRenderingProviderName, "diagnosticsLatency", 0)
	Evidence.record("diagnostics captured", {})
	return Diagnostics.capture(Runtime)
end

function Runtime.getSnapshot()
	Profiler.record(Types.RobloxRenderingProviderName, "snapshotLatency", 0)
	Evidence.record("snapshot captured", {})
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
	Capabilities.clear()
	Evidence.clear()
	Metrics.clear()
	Negotiation.clear()
	Profiler.clear()
	Renderers.clear()
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

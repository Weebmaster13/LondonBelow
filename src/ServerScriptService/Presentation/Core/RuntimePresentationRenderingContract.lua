--!strict

local Acknowledgements = require(script.Parent.RendererAcknowledgementRegistry)
local AccessibilityReferences = require(script.Parent.RenderingAccessibilityReferenceRegistry)
local AssetReferences = require(script.Parent.RenderingAssetReferenceRegistry)
local Builder = require(script.Parent.RenderingRequestBuilder)
local Contracts = require(script.Parent.RenderingContractRegistry)
local Diagnostics = require(script.Parent.RenderingDiagnostics)
local Evidence = require(script.Parent.RenderingEvidence)
local LocalizationReferences = require(script.Parent.RenderingLocalizationReferenceRegistry)
local Metrics = require(script.Parent.RenderingMetrics)
local Profiler = require(script.Parent.RenderingProfiler)
local RendererCapabilities = require(script.Parent.RendererCapabilityRegistry)
local RendererCompatibility = require(script.Parent.RendererCompatibilityValidator)
local Requests = require(script.Parent.RenderingRequestRegistry)
local Serialization = require(script.Parent.PresentationSerialization)
local Snapshots = require(script.Parent.RenderingSnapshots)
local Synchronization = require(script.Parent.RenderingSynchronizationManager)
local Types = require(script.Parent.PresentationTypes)
local Validation = require(script.Parent.RenderingValidation)

local Runtime = {}
local shutdown = false
local counters = {
	requestsCreated = 0,
	rendererCapabilitiesRegistered = 0,
	acknowledgementsRegistered = 0,
	failures = 0,
	lastFailure = nil :: any?,
}
local failures = {}

local function fail(code: string, message: string, payload: any?)
	counters.failures += 1
	counters.lastFailure = {
		code = code,
		message = message,
		payload = Serialization.diagnosticCopy(payload or {}),
	}
	failures[#failures + 1] = counters.lastFailure
	Metrics.increment("validationFailures")
	Evidence.record("validation failure", counters.lastFailure)
	return { ok = false, code = code, message = message }
end

function Runtime.registerDefaultContract()
	if shutdown then
		return fail(Types.RenderingContractFailureType.RuntimeShutdown, "runtime is shut down", {})
	end
	local result = Contracts.registerDefault()
	if not result.ok then
		return fail(result.code, result.message, {})
	end
	return result
end

function Runtime.registerRendererCapability(capability: any)
	if shutdown then
		return fail(
			Types.RenderingContractFailureType.RuntimeShutdown,
			"runtime is shut down",
			capability
		)
	end
	local result = RendererCapabilities.register(capability)
	if not result.ok then
		return fail(result.code, result.message, capability)
	end
	counters.rendererCapabilitiesRegistered += 1
	return result
end

function Runtime.createRenderingRequest(input: any)
	if shutdown then
		return fail(
			Types.RenderingContractFailureType.RuntimeShutdown,
			"runtime is shut down",
			input
		)
	end
	local built = Builder.build(input)
	if not built.ok then
		return fail(built.code, built.message, input)
	end
	local registered = Requests.register(built.request)
	if not registered.ok then
		return fail(registered.code, registered.message, built.request)
	end
	counters.requestsCreated += 1
	Profiler.record(registered.request.renderingRequestId, "requestRegistrationDuration", 0)
	return registered
end

function Runtime.evaluateRendererCompatibility(requestId: string, rendererCapabilityId: string)
	local request = Requests.get(requestId)
	if request == nil then
		return fail(
			Types.RenderingContractFailureType.UnknownRenderingRequest,
			"unknown rendering request",
			{ requestId = requestId }
		)
	end
	local result = RendererCompatibility.evaluate(request, rendererCapabilityId)
	Evidence.record("compatibility evaluated", result.result)
	return result
end

function Runtime.acknowledgeRenderingRequest(acknowledgement: any)
	if shutdown then
		return fail(
			Types.RenderingContractFailureType.RuntimeShutdown,
			"runtime is shut down",
			acknowledgement
		)
	end
	local result = Acknowledgements.register(acknowledgement)
	if not result.ok then
		return fail(result.code, result.message, acknowledgement)
	end
	counters.acknowledgementsRegistered += 1
	Profiler.record(
		result.acknowledgement.renderingRequestId,
		"acknowledgementValidationDuration",
		0
	)
	return result
end

function Runtime.resolveRenderingSynchronization(requestId: string)
	local result = Synchronization.resolve(requestId)
	if not result.ok then
		return fail(result.code, result.message, { renderingRequestId = requestId })
	end
	Profiler.record(requestId, "synchronizationResolutionDuration", 0)
	return result
end

function Runtime.getRenderingRequest(requestId: string)
	return Requests.get(requestId)
end

function Runtime.inspectRendererCapabilities()
	return RendererCapabilities.inspect()
end

function Runtime.inspectRenderingRequests()
	return Requests.inspect()
end

function Runtime.inspectRenderingAcknowledgements()
	return Acknowledgements.inspect()
end

function Runtime.getLocalizationReferences()
	return LocalizationReferences.inspect()
end

function Runtime.getAccessibilityReferences()
	return AccessibilityReferences.inspect()
end

function Runtime.getAssetReferences()
	return AssetReferences.inspect()
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
	AccessibilityReferences.clear()
	AssetReferences.clear()
	Builder.clear()
	Contracts.clear()
	Evidence.clear()
	LocalizationReferences.clear()
	Metrics.clear()
	Profiler.clear()
	RendererCapabilities.clear()
	Requests.clear()
	Synchronization.clear()
	Contracts.registerDefault()
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

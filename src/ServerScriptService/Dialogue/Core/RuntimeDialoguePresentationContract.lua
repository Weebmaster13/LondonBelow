--!strict

local Accessibility = require(script.Parent.AccessibilityMetadataRegistry)
local Acknowledgements = require(script.Parent.PresentationAcknowledgementRegistry)
local Builder = require(script.Parent.PresentationRequestBuilder)
local Contracts = require(script.Parent.PresentationContractRegistry)
local Diagnostics = require(script.Parent.PresentationDiagnostics)
local Evidence = require(script.Parent.PresentationEvidence)
local Localization = require(script.Parent.LocalizationReferenceRegistry)
local Metrics = require(script.Parent.PresentationMetrics)
local Profiler = require(script.Parent.PresentationProfiler)
local Requests = require(script.Parent.PresentationRequestRegistry)
local Serialization = require(script.Parent.DialogueSerialization)
local Snapshots = require(script.Parent.PresentationSnapshots)
local Synchronization = require(script.Parent.PresentationSynchronizationManager)
local Types = require(script.Parent.DialoguePresentationTypes)
local Validation = require(script.Parent.PresentationValidation)

local Runtime = {}
local shutdown = false
local counters = {
	requestsCreated = 0,
	acknowledgementsReceived = 0,
	synchronizationResolutions = 0,
	validationFailures = 0,
	lifecycleCounts = {},
	lastFailure = nil :: any?,
}

local function fail(code: string, message: string, payload: any?)
	counters.validationFailures += 1
	counters.lastFailure =
		{ code = code, message = message, payload = Serialization.deepCopy(payload) }
	Metrics.increment("validationFailures")
	Evidence.record("presentation validation failure", counters.lastFailure)
	return { ok = false, code = code, message = message }
end

local function defaultContract()
	return {
		contractId = Types.ContractId,
		version = "1.0.0",
		owner = "Dialogue",
		domain = "Dialogue",
		authority = "Server",
		providerName = Types.ProviderName,
		snapshotProvider = Types.ProviderName,
		diagnosticsProvider = Types.ProviderName,
		dependencies = {
			"Dialogue Runtime Capability Foundation",
			"Dialogue Runtime Execution and State Management",
			"Dialogue Interaction and Runtime Event Coordination",
		},
		phase = 175,
		certificationStatus = "ProductionCandidate",
	}
end

function Runtime.registerDefaultContract()
	local existing = Contracts.get(Types.ContractId)
	if existing ~= nil then
		return { ok = true, code = "Ok", contract = existing }
	end
	return Contracts.register(defaultContract())
end

function Runtime.createPresentationRequest(input: any)
	if shutdown then
		return fail(Types.FailureType.RuntimeShutdown, "runtime is shut down", input)
	end
	Runtime.registerDefaultContract()
	local built = Builder.build(input)
	if not built.ok then
		return fail(built.code, built.message, input)
	end
	local localized =
		Localization.register(built.request.presentationId, built.request.localizationReferences)
	if not localized.ok then
		return fail(localized.code, localized.message, input)
	end
	local accessibility =
		Accessibility.register(built.request.presentationId, built.request.accessibilityMetadata)
	if not accessibility.ok then
		return fail(accessibility.code, accessibility.message, input)
	end
	local created = Requests.create(built.request)
	if not created.ok then
		return fail(created.code, created.message, input)
	end
	counters.requestsCreated += 1
	counters.lifecycleCounts[created.request.status] = (
		counters.lifecycleCounts[created.request.status] or 0
	) + 1
	Profiler.record(created.request.presentationId, "requestBuildDuration", 0)
	Evidence.record(
		"presentation request validated",
		{ presentationId = created.request.presentationId }
	)
	return created
end

function Runtime.getPresentationRequest(presentationId: string)
	return Requests.get(presentationId)
end

function Runtime.inspectPresentationRequests()
	return Requests.inspect()
end

function Runtime.acknowledgePresentation(acknowledgement: any)
	if shutdown then
		return fail(Types.FailureType.RuntimeShutdown, "runtime is shut down", acknowledgement)
	end
	local result = Acknowledgements.register(acknowledgement)
	if not result.ok then
		return fail(result.code, result.message, acknowledgement)
	end
	counters.acknowledgementsReceived += 1
	counters.lifecycleCounts[result.acknowledgement.status] = (
		counters.lifecycleCounts[result.acknowledgement.status] or 0
	) + 1
	Profiler.record(result.acknowledgement.presentationId, "acknowledgementValidationDuration", 0)
	return result
end

function Runtime.getPresentationAcknowledgement(acknowledgementId: string)
	return Acknowledgements.get(acknowledgementId)
end

function Runtime.resolveSynchronizationState(presentationId: string)
	local result = Synchronization.resolve(presentationId)
	if not result.ok then
		return fail(result.code, result.message, { presentationId = presentationId })
	end
	counters.synchronizationResolutions += 1
	Profiler.record(presentationId, "synchronizationResolutionDuration", 0)
	return result
end

function Runtime.getLocalizationReferences(presentationId: string)
	return Localization.get(presentationId)
end

function Runtime.getAccessibilityMetadata(presentationId: string)
	return Accessibility.get(presentationId)
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
	Evidence.record("runtime shutdown", {})
end

function Runtime.reset()
	shutdown = false
	for key in pairs(counters) do
		if key == "lastFailure" then
			counters[key] = nil
		elseif key == "lifecycleCounts" then
			counters[key] = {}
		else
			counters[key] = 0
		end
	end
	Accessibility.clear()
	Acknowledgements.clear()
	Contracts.clear()
	Evidence.clear()
	Localization.clear()
	Metrics.clear()
	Profiler.clear()
	Requests.clear()
	Synchronization.clear()
	Runtime.registerDefaultContract()
	Evidence.record("runtime reset", {})
end

function Runtime.getCounters()
	return Serialization.deepCopy(counters)
end

Runtime.reset()

return Runtime

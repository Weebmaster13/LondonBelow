--!strict

local Serialization = require(script.Parent.PresentationSerialization)

local Metrics = {}
local counters = {
	contractsRegistered = 0,
	rendererCapabilitiesRegistered = 0,
	renderingRequestsCreated = 0,
	renderingRequestsRejected = 0,
	descriptorsValidated = 0,
	descriptorValidationFailures = 0,
	compatibilityEvaluations = 0,
	compatibleRendererResults = 0,
	incompatibleRendererResults = 0,
	acknowledgementsRegistered = 0,
	acknowledgementsRejected = 0,
	synchronizationResolutions = 0,
	synchronizationCompletions = 0,
	localizationReferencesRegistered = 0,
	accessibilityReferencesRegistered = 0,
	assetReferencesRegistered = 0,
	validationFailures = 0,
	budgetFailures = 0,
}

function Metrics.increment(counter: string)
	if counters[counter] == nil then
		counters[counter] = 0
	end
	counters[counter] += 1
end

function Metrics.inspect()
	return Serialization.deepCopy(counters)
end

function Metrics.clear()
	for key in pairs(counters) do
		counters[key] = 0
	end
end

return Metrics

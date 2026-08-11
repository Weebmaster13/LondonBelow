--!strict

local Serialization = require(script.Parent.PresentationSerialization)

local Metrics = {}
local counters = {
	definitionsRegistered = 0,
	definitionsRejected = 0,
	compositionsCreated = 0,
	compositionsResolved = 0,
	compositionsActivated = 0,
	compositionsSuperseded = 0,
	compositionsReleased = 0,
	compilationFailures = 0,
	graphValidationFailures = 0,
	layoutValidationFailures = 0,
	staleRevisionRejections = 0,
	ownershipConflicts = 0,
	nodesCompiled = 0,
	layersCompiled = 0,
	regionsCompiled = 0,
	accessibilityNodes = 0,
	localizationSlots = 0,
	assetReferences = 0,
	validationFailures = 0,
	runtimeFailures = 0,
}

function Metrics.increment(name: string, amount: number?)
	if counters[name] ~= nil then
		counters[name] += amount or 1
	end
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

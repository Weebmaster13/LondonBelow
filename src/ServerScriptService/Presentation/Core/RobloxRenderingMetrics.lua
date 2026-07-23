--!strict

local Serialization = require(script.Parent.PresentationSerialization)

local Metrics = {}
local counters = {
	registeredRenderers = 0,
	registeredCapabilities = 0,
	compatibilityChecks = 0,
	successfulNegotiations = 0,
	failedNegotiations = 0,
	configurationLoads = 0,
	validationFailures = 0,
	runtimeFailures = 0,
}

function Metrics.increment(name: string)
	if counters[name] ~= nil then
		counters[name] += 1
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

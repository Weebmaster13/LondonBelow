--!strict

local Serialization = require(script.Parent.CapabilitySerialization)

local Metrics = {}
local counters = {
	registeredCapabilities = 0,
	runningCapabilities = 0,
	initializationDuration = 0,
	dependencyFailures = 0,
	healthFailures = 0,
	recoveryCount = 0,
}

function Metrics.set(key: string, value: number)
	if counters[key] ~= nil then
		counters[key] = value
	end
end

function Metrics.increment(key: string)
	if counters[key] ~= nil then
		counters[key] += 1
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

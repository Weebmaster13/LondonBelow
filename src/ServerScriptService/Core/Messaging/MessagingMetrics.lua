--!strict

local Serialization = require(script.Parent.MessagingSerialization)

local Metrics = {}

local counters = {
	registeredConsumers = 0,
	activeConsumers = 0,
	subscriptions = 0,
	dependencyDepth = 0,
	initializationCount = 0,
	shutdownCount = 0,
	messageThroughput = 0,
	failures = 0,
}

function Metrics.set(values: { [string]: number })
	for key, value in pairs(values) do
		if counters[key] ~= nil then
			counters[key] = value
		end
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

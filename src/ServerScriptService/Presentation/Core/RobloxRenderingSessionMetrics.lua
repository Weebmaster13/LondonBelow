--!strict

local Serialization = require(script.Parent.PresentationSerialization)

local Metrics = {}
local counters = {
	activeRendererSessions = 0,
	mappedExecutionSessions = 0,
	reservationCount = 0,
	ownershipTransfers = 0,
	lifecycleTransitions = 0,
	schedulingOperations = 0,
	validationFailures = 0,
	runtimeFailures = 0,
}

function Metrics.increment(name: string)
	if counters[name] ~= nil then
		counters[name] += 1
	end
end

function Metrics.decrement(name: string)
	if counters[name] ~= nil and counters[name] > 0 then
		counters[name] -= 1
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

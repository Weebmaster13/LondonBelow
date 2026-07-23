--!strict

local Serialization = require(script.Parent.PresentationSerialization)

local Metrics = {}
local counters = {
	runtimesRegistered = 0,
	renderersRegistered = 0,
	renderersAvailable = 0,
	renderingSessions = 0,
	assignments = 0,
	lifecycleTransitions = 0,
	acknowledgements = 0,
	synchronizationCompletions = 0,
	validationFailures = 0,
	runtimeFailures = 0,
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

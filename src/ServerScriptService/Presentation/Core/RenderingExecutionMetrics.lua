--!strict

local Serialization = require(script.Parent.PresentationSerialization)

local Metrics = {}
local counters = {
	queuedSessions = 0,
	activeExecutions = 0,
	completedExecutions = 0,
	cancelledExecutions = 0,
	expiredExecutions = 0,
	suspensionCount = 0,
	resumeCount = 0,
	acknowledgements = 0,
	synchronizationCompletions = 0,
	validationFailures = 0,
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

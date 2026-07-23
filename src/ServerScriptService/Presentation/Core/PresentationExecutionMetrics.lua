--!strict

local Serialization = require(script.Parent.PresentationSerialization)

local Metrics = {}
local counters = {
	executionsStarted = 0,
	executionsCompleted = 0,
	executionsSuspended = 0,
	executionsResumed = 0,
	acknowledgementsProduced = 0,
	schedulerDecisions = 0,
	synchronizationCompletions = 0,
	queueOperations = 0,
	validationFailures = 0,
}

function Metrics.increment(key: string, amount: number?)
	counters[key] = (counters[key] or 0) + (amount or 1)
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

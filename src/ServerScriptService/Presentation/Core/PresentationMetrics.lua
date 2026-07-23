--!strict

local Serialization = require(script.Parent.PresentationSerialization)

local Metrics = {}
local counters = {
	sessionsCreated = 0,
	sessionsQueued = 0,
	sessionsAssigned = 0,
	sessionsCompleted = 0,
	acknowledgementsProduced = 0,
	synchronizationCompletions = 0,
	queueOperations = 0,
	lifecycleTransitions = 0,
	consumerRegistrations = 0,
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

--!strict

local Serialization = require(script.Parent.DialogueSerialization)

local Metrics = {}
local counters = {
	contractsRegistered = 0,
	requestsCreated = 0,
	requestsPending = 0,
	requestsCompleted = 0,
	requestsCancelled = 0,
	requestsRejected = 0,
	acknowledgementsReceived = 0,
	acknowledgementsAccepted = 0,
	acknowledgementFailures = 0,
	synchronizationCompletions = 0,
	localizationReferencesRegistered = 0,
	accessibilityRecordsRegistered = 0,
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

--!strict

local Serialization = require(script.Parent.DialogueSerialization)

local Metrics = {}
local counters = {
	interactionsCreated = 0,
	responsesProcessed = 0,
	validationFailures = 0,
	timeouts = 0,
	interruptions = 0,
	resumes = 0,
	nestedConversations = 0,
	queueOperations = 0,
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

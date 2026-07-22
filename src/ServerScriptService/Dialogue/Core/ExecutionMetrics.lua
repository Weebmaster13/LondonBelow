--!strict

local Serialization = require(script.Parent.DialogueSerialization)

local Metrics = {}
local counters = {
	activeConversations = 0,
	completedConversations = 0,
	cancelledConversations = 0,
	nodeExecutions = 0,
	transitions = 0,
	conditionsEvaluated = 0,
	variableMutations = 0,
	choicesSelected = 0,
	schedulerOperations = 0,
}

function Metrics.increment(name: string)
	if counters[name] ~= nil then
		counters[name] += 1
	end
end

function Metrics.set(name: string, value: number)
	if counters[name] ~= nil then
		counters[name] = value
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

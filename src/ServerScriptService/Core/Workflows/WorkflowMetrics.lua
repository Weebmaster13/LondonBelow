--!strict

local Serialization = require(script.Parent.WorkflowSerialization)

local Metrics = {}

local counters = {
	workflowsStarted = 0,
	workflowsCompleted = 0,
	averageDuration = 0,
	timeoutCount = 0,
	retryCount = 0,
	cancellationCount = 0,
	failures = 0,
}

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

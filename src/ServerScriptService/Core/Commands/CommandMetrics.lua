--!strict

local Latency = require(script.Parent.CommandLatency)
local Serialization = require(script.Parent.CommandSerialization)
local Types = require(script.Parent.CommandTypes)

local Metrics = {}
local data = {
	submitted = 0,
	queued = 0,
	scheduled = 0,
	executed = 0,
	succeeded = 0,
	failed = 0,
	retriesScheduled = 0,
	lockContention = 0,
	queueDepthTotal = 0,
	queueDepthSamples = 0,
	maximumQueueDepth = 0,
	totalQueueWait = 0,
	queueWaitSamples = 0,
	totalExecutionDuration = 0,
	longestExecution = 0,
	shortestExecution = nil :: number?,
	failureCounts = {},
	throughputHistory = {},
}

local function trimThroughput()
	while #data.throughputHistory > Types.Limits.MaxThroughputHistory do
		table.remove(data.throughputHistory, 1)
	end
end

function Metrics.recordSubmission()
	data.submitted += 1
end

function Metrics.recordQueued(queueDepth: number)
	data.queued += 1
	data.queueDepthTotal += queueDepth
	data.queueDepthSamples += 1
	data.maximumQueueDepth = math.max(data.maximumQueueDepth, queueDepth)
end

function Metrics.recordScheduled(command: any)
	data.scheduled += 1
	if command.admissionTimestamp ~= nil and command.scheduledTimestamp ~= nil then
		data.totalQueueWait += math.max(0, command.scheduledTimestamp - command.admissionTimestamp)
		data.queueWaitSamples += 1
	end
end

function Metrics.recordExecution(result: any)
	data.executed += 1
	local duration = if result.commandResult ~= nil
		then result.commandResult.executionDuration or 0
		else 0
	data.totalExecutionDuration += duration
	data.longestExecution = math.max(data.longestExecution, duration)
	if data.shortestExecution == nil then
		data.shortestExecution = duration
	else
		data.shortestExecution = math.min(data.shortestExecution :: number, duration)
	end
	Latency.record(duration)
	if result.ok then
		data.succeeded += 1
	else
		data.failed += 1
		local code = result.code or Types.FailureType.ExecutionFailure
		data.failureCounts[code] = (data.failureCounts[code] or 0) + 1
	end
	table.insert(data.throughputHistory, {
		timestamp = os.clock(),
		executed = data.executed,
	})
	trimThroughput()
end

function Metrics.recordRetryScheduled()
	data.retriesScheduled += 1
end

function Metrics.recordLockContention()
	data.lockContention += 1
end

function Metrics.inspect()
	local averageQueueDepth = if data.queueDepthSamples > 0
		then data.queueDepthTotal / data.queueDepthSamples
		else 0
	local averageQueueWait = if data.queueWaitSamples > 0
		then data.totalQueueWait / data.queueWaitSamples
		else 0
	local averageExecutionDuration = if data.executed > 0
		then data.totalExecutionDuration / data.executed
		else 0
	return Serialization.deepCopy({
		submitted = data.submitted,
		queued = data.queued,
		scheduled = data.scheduled,
		executed = data.executed,
		succeeded = data.succeeded,
		failed = data.failed,
		retriesScheduled = data.retriesScheduled,
		lockContention = data.lockContention,
		averageQueueDepth = averageQueueDepth,
		maximumQueueDepth = data.maximumQueueDepth,
		averageQueueWait = averageQueueWait,
		averageExecutionDuration = averageExecutionDuration,
		longestExecution = data.longestExecution,
		shortestExecution = data.shortestExecution or 0,
		failureCounts = data.failureCounts,
		latencyHistogram = Latency.inspect(),
		throughputHistory = data.throughputHistory,
	})
end

function Metrics.clear()
	data.submitted = 0
	data.queued = 0
	data.scheduled = 0
	data.executed = 0
	data.succeeded = 0
	data.failed = 0
	data.retriesScheduled = 0
	data.lockContention = 0
	data.queueDepthTotal = 0
	data.queueDepthSamples = 0
	data.maximumQueueDepth = 0
	data.totalQueueWait = 0
	data.queueWaitSamples = 0
	data.totalExecutionDuration = 0
	data.longestExecution = 0
	data.shortestExecution = nil
	table.clear(data.failureCounts)
	table.clear(data.throughputHistory)
	Latency.clear()
end

return Metrics

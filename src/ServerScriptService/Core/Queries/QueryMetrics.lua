--!strict
local Serialization = require(script.Parent.QuerySerialization)
local Metrics = {}
local data =
	{ count = 0, failed = 0, totalDuration = 0, cacheHits = 0, cacheMisses = 0, queueWaitTotal = 0 }
function Metrics.record(result: any)
	data.count += 1
	if result.ok == false then
		data.failed += 1
	end
	data.totalDuration += if result.result ~= nil then result.result.executionDuration or 0 else 0
end
function Metrics.inspect()
	return Serialization.deepCopy({
		queryCount = data.count,
		failedQueries = data.failed,
		averageDuration = if data.count > 0 then data.totalDuration / data.count else 0,
		cacheHitRate = data.cacheHits,
		cacheMissRate = data.cacheMisses,
		queueWait = data.queueWaitTotal,
		throughput = data.count,
	})
end
function Metrics.clear()
	data.count = 0
	data.failed = 0
	data.totalDuration = 0
	data.cacheHits = 0
	data.cacheMisses = 0
	data.queueWaitTotal = 0
end
return Metrics

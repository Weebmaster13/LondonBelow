--!strict
local Serialization = require(script.Parent.QuerySerialization)
local Profiler = {}
local hottest = {}
local slowest = {}
local largest = {}
function Profiler.record(query: any, result: any)
	hottest[query.queryType] = (hottest[query.queryType] or 0) + 1
	slowest[query.queryType] = math.max(
		slowest[query.queryType] or 0,
		if result.result ~= nil then result.result.executionDuration or 0 else 0
	)
	largest[query.queryType] = #(tostring(result.result and result.result.payload or ""))
end
function Profiler.inspect()
	return Serialization.deepCopy({
		slowestQueries = slowest,
		hottestQueryTypes = hottest,
		largestPayloads = largest,
		longestWaits = {},
		highestCacheMisses = {},
	})
end
function Profiler.clear()
	table.clear(hottest)
	table.clear(slowest)
	table.clear(largest)
end
return Profiler

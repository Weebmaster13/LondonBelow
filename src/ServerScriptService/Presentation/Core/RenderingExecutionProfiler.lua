--!strict

local Serialization = require(script.Parent.PresentationSerialization)
local Types = require(script.Parent.PresentationTypes)

local Profiler = {}
local records = {}

function Profiler.record(scopeId: string, metricName: string, duration: number)
	if #records >= Types.RenderingExecutionLimits.MaxProfilerRecords then
		table.remove(records, 1)
	end
	records[#records + 1] = {
		scopeId = scopeId,
		metricName = metricName,
		duration = duration,
		ordinal = #records + 1,
	}
end

function Profiler.inspect()
	return Serialization.deepCopy(records)
end

function Profiler.clear()
	table.clear(records)
end

return Profiler

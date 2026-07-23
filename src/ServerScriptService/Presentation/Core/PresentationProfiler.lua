--!strict

local Serialization = require(script.Parent.PresentationSerialization)
local Types = require(script.Parent.PresentationTypes)

local Profiler = {}
local records = {}

function Profiler.record(targetId: string, metric: string, duration: number)
	if #records >= Types.Limits.MaxRuntimeProfilerRecords then
		table.remove(records, 1)
	end
	records[#records + 1] = {
		targetId = targetId,
		metric = metric,
		duration = duration,
	}
end

function Profiler.inspect()
	return Serialization.deepCopy(records)
end

function Profiler.clear()
	table.clear(records)
end

return Profiler

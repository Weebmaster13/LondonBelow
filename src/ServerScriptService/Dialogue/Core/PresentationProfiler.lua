--!strict

local Serialization = require(script.Parent.DialogueSerialization)
local Types = require(script.Parent.DialoguePresentationTypes)

local Profiler = {}
local records = {}

function Profiler.record(targetId: string, metric: string, duration: number)
	if #records >= Types.Limits.MaxProfilerRecords then
		table.remove(records, 1)
	end
	records[#records + 1] = {
		targetId = targetId,
		metric = metric,
		duration = duration,
	}
end

function Profiler.inspect()
	return Serialization.copyArray(records)
end

function Profiler.clear()
	table.clear(records)
end

return Profiler

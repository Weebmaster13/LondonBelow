--!strict

local Serialization = require(script.Parent.DialogueSerialization)

local Profiler = {}
local records = {}

function Profiler.record(subjectId: string, metric: string, value: number)
	records[#records + 1] = {
		subjectId = subjectId,
		metric = metric,
		value = value,
	}
end

function Profiler.inspect()
	return Serialization.deepCopy(records)
end

function Profiler.clear()
	table.clear(records)
end

return Profiler

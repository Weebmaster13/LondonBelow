--!strict

local Serialization = require(script.Parent.PresentationSerialization)
local Types = require(script.Parent.PresentationTypes)

local Profiler = {}
local records = {}
local nextOrdinal = 0

function Profiler.record(subjectId: string, metric: string, duration: number)
	if #records >= Types.RobloxRenderingSessionLimits.MaxProfilerRecords then
		return false
	end
	nextOrdinal += 1
	records[#records + 1] = {
		ordinal = nextOrdinal,
		subjectId = subjectId,
		metric = metric,
		duration = duration,
	}
	return true
end

function Profiler.inspect()
	return Serialization.deepCopy(records)
end

function Profiler.clear()
	table.clear(records)
	nextOrdinal = 0
end

return Profiler

--!strict

local Serialization = require(script.Parent.PresentationSerialization)
local Types = require(script.Parent.PresentationTypes)

local Profiler = {}
local records = {}
local nextOrdinal = 0

function Profiler.record(ownerId: string, stage: string, duration: number)
	if #records >= Types.VisualCompositionLimits.MaxProfilerRecords then
		table.remove(records, 1)
	end
	nextOrdinal += 1
	records[#records + 1] = {
		ordinal = nextOrdinal,
		ownerId = ownerId,
		stage = stage,
		duration = duration,
	}
end

function Profiler.inspect()
	return Serialization.deepCopy(records)
end

function Profiler.clear()
	table.clear(records)
	nextOrdinal = 0
end

return Profiler

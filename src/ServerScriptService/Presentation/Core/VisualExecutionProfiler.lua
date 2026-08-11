--!strict

local Serialization = require(script.Parent.PresentationSerialization)
local Types = require(script.Parent.PresentationTypes)

local Profiler = {}
local records = {}

function Profiler.record(subjectId: string, phaseName: string, duration: number)
	records[#records + 1] = {
		recordId = "visual.execution.profiler." .. tostring(#records + 1),
		subjectId = subjectId,
		phaseName = phaseName,
		duration = duration,
	}
	while #records > Types.VisualExecutionLimits.MaxProfilerRecords do
		table.remove(records, 1)
	end
end

function Profiler.inspect()
	return Serialization.deepCopy(records)
end

function Profiler.clear()
	table.clear(records)
end

return Profiler

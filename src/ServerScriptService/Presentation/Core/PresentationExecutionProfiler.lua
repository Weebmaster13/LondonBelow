--!strict

local Serialization = require(script.Parent.PresentationSerialization)
local Types = require(script.Parent.PresentationTypes)

local Profiler = {}
local records = {}

function Profiler.record(executionId: string, metric: string, duration: number)
	if #records >= Types.ExecutionLimits.MaxExecutionProfilerRecords then
		table.remove(records, 1)
	end
	records[#records + 1] = { executionId = executionId, metric = metric, duration = duration }
end

function Profiler.inspect()
	return Serialization.deepCopy(records)
end

function Profiler.clear()
	table.clear(records)
end

return Profiler

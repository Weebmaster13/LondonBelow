--!strict

local Serialization = require(script.Parent.DomainSerialization)

local Profiler = {}
local records = {}

function Profiler.record(capabilityId: string, metric: string, value: number)
	table.insert(records, {
		capabilityId = capabilityId,
		metric = metric,
		value = value,
		recordedAt = os.clock(),
	})
end

function Profiler.inspect()
	return Serialization.copyArray(records)
end

function Profiler.clear()
	table.clear(records)
end

return Profiler

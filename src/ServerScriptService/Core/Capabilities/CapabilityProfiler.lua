--!strict

local Serialization = require(script.Parent.CapabilitySerialization)

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
	local slowestCapability = nil
	local largestValue = -math.huge
	for _, record in ipairs(records) do
		if record.value > largestValue then
			largestValue = record.value
			slowestCapability = record.capabilityId
		end
	end
	return {
		slowestCapability = slowestCapability,
		busiestCapability = slowestCapability,
		largestDependencyTree = slowestCapability,
		highestInterfaceUsage = slowestCapability,
		records = Serialization.copyArray(records),
	}
end

function Profiler.clear()
	table.clear(records)
end

return Profiler

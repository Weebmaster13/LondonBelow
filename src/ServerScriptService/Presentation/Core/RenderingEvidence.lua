--!strict

local Serialization = require(script.Parent.PresentationSerialization)
local Types = require(script.Parent.PresentationTypes)

local Evidence = {}
local records = {}
local nextOrdinal = 0

function Evidence.record(eventName: string, payload: any)
	if #records >= Types.RenderingContractLimits.MaxEvidence then
		table.remove(records, 1)
	end
	nextOrdinal += 1
	local record = {
		evidenceId = string.format("presentation.rendering.contract.evidence.%06d", nextOrdinal),
		eventName = eventName,
		ordinal = nextOrdinal,
		payload = Serialization.diagnosticCopy(payload or {}),
	}
	records[#records + 1] = record
	return Serialization.deepCopy(record)
end

function Evidence.inspect()
	return Serialization.deepCopy(records)
end

function Evidence.clear()
	table.clear(records)
	nextOrdinal = 0
end

return Evidence

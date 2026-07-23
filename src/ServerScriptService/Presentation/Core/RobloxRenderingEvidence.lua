--!strict

local Serialization = require(script.Parent.PresentationSerialization)
local Types = require(script.Parent.PresentationTypes)

local Evidence = {}
local records = {}
local nextOrdinal = 0

function Evidence.record(kind: string, payload: any)
	if #records >= Types.RobloxRenderingLimits.MaxEvidence then
		return false
	end
	nextOrdinal += 1
	records[#records + 1] = {
		ordinal = nextOrdinal,
		kind = kind,
		payload = Serialization.diagnosticCopy(payload or {}),
	}
	return true
end

function Evidence.inspect()
	return Serialization.deepCopy(records)
end

function Evidence.clear()
	table.clear(records)
	nextOrdinal = 0
end

return Evidence

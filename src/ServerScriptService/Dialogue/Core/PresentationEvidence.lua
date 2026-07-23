--!strict

local Serialization = require(script.Parent.DialogueSerialization)
local Types = require(script.Parent.DialoguePresentationTypes)

local Evidence = {}
local records = {}
local nextOrdinal = 0

function Evidence.record(kind: string, payload: any?)
	if #records >= Types.Limits.MaxEvidence then
		table.remove(records, 1)
	end
	nextOrdinal += 1
	records[#records + 1] = {
		evidenceId = string.format("dialogue.presentation.evidence.%06d", nextOrdinal),
		kind = kind,
		ordinal = nextOrdinal,
		payload = Serialization.deepCopy(payload or {}),
	}
end

function Evidence.inspect()
	return Serialization.copyArray(records)
end

function Evidence.clear()
	table.clear(records)
	nextOrdinal = 0
end

return Evidence

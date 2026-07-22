--!strict

local Serialization = require(script.Parent.DialogueSerialization)
local Types = require(script.Parent.DialogueInteractionTypes)

local Evidence = {}
local records = {}
local nextId = 0

function Evidence.record(kind: string, payload: any?)
	nextId += 1
	if #records >= Types.Limits.MaxEvidence then
		table.remove(records, 1)
	end
	records[#records + 1] = {
		evidenceId = string.format("dialogue.interaction.evidence.%06d", nextId),
		kind = kind,
		payload = Serialization.deepCopy(payload or {}),
	}
end

function Evidence.inspect()
	return Serialization.deepCopy(records)
end

function Evidence.clear()
	table.clear(records)
	nextId = 0
end

return Evidence

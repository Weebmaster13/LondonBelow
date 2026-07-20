--!strict

local Serialization = require(script.Parent.GameplayFlowSerialization)
local Types = require(script.Parent.GameplayFlowTypes)

local Evidence = {}

local records: { any } = {}
local nextSequence = 0

function Evidence.record(kind: string, payload: any?)
	nextSequence += 1
	local record = {
		evidenceId = "gameplayFlow.evidence." .. tostring(nextSequence),
		kind = kind,
		sequence = nextSequence,
		payload = Serialization.deepCopy(payload or {}),
	}
	table.insert(records, record)
	if #records > Types.Limits.MaxEvidence then
		table.remove(records, 1)
	end
	return Serialization.deepCopy(record)
end

function Evidence.all()
	return Serialization.deepCopy(records)
end

function Evidence.count(): number
	return #records
end

function Evidence.clear()
	table.clear(records)
	nextSequence = 0
end

return Evidence

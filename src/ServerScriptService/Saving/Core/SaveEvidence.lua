--!strict

local Serialization = require(script.Parent.SaveSerialization)
local Types = require(script.Parent.SaveTypes)

local Evidence = {}
local records: { any } = {}
local nextSequence = 0

function Evidence.record(kind: string, payload: any?)
	nextSequence += 1
	local record = {
		evidenceId = "saveRuntime.evidence." .. tostring(nextSequence),
		kind = kind,
		sequence = nextSequence,
		payload = Serialization.diagnosticCopy(payload or {}),
	}
	table.insert(records, record)
	if #records > Types.Limits.MaxEvidence then
		table.remove(records, 1)
	end
	return Serialization.deepCopy(record)
end

function Evidence.inspect()
	return {
		evidenceCount = #records,
		records = Serialization.deepCopy(records),
	}
end

function Evidence.clear()
	table.clear(records)
	nextSequence = 0
end

return Evidence

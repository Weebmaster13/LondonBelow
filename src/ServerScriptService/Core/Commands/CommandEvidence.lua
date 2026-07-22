--!strict

local Serialization = require(script.Parent.CommandSerialization)
local Types = require(script.Parent.CommandTypes)

local Evidence = {}
local records: { any } = {}
local sequence = 0

function Evidence.record(kind: string, payload: any?)
	sequence += 1
	table.insert(records, {
		sequence = sequence,
		kind = kind,
		payload = Serialization.deepCopy(payload or {}),
		source = "static validation",
	})
	while #records > Types.Limits.MaxEvidence do
		table.remove(records, 1)
	end
end

function Evidence.inspect()
	return Serialization.copyArray(records)
end

function Evidence.clear()
	table.clear(records)
	sequence = 0
end

return Evidence

--!strict

local Serialization = require(script.Parent.QuerySerialization)
local Types = require(script.Parent.QueryTypes)

local Evidence = {}
local records: { any } = {}

function Evidence.record(kind: string, payload: any)
	table.insert(records, {
		kind = kind,
		payload = Serialization.deepCopy(payload),
		timestamp = os.clock(),
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
end

return Evidence

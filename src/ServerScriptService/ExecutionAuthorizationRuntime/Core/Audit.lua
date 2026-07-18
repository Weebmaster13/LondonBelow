--!strict

local Serialization = require(script.Parent.Serialization)
local Types = require(script.Parent.Types)

local Audit = {}

function Audit.record(records: { any }, eventKind: string, payload: any)
	if #records >= Types.Limits.MaxAuditRecords then
		table.remove(records, 1)
	end
	table.insert(records, {
		eventKind = eventKind,
		sequence = #records + 1,
		timestamp = Types.StableTimestamp,
		payload = Serialization.deepCopy(payload),
	})
end

function Audit.snapshot(records: { any }): { any }
	return Serialization.deepCopy(records)
end

return Audit

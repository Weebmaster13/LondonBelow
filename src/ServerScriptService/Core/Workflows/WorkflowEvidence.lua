--!strict

local Serialization = require(script.Parent.WorkflowSerialization)
local Types = require(script.Parent.WorkflowTypes)

local Evidence = {}
local records = {}
local sequence = 0

function Evidence.record(kind: string, payload: any)
	sequence += 1
	table.insert(records, {
		evidenceId = string.format("workflow.evidence.%06d", sequence),
		kind = kind,
		sequence = sequence,
		payload = Serialization.deepCopy(payload),
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

--!strict

local Serialization = require(script.Parent.PresentationSerialization)
local Types = require(script.Parent.PresentationTypes)

local Evidence = {}
local records = {}
local nextOrdinal = 0

function Evidence.record(kind: string, payload: any?)
	if #records >= Types.ExecutionLimits.MaxExecutionEvidence then
		table.remove(records, 1)
	end
	nextOrdinal += 1
	records[#records + 1] = {
		evidenceId = string.format("presentation.execution.evidence.%06d", nextOrdinal),
		kind = kind,
		ordinal = nextOrdinal,
		payload = Serialization.diagnosticCopy(payload or {}),
	}
end

function Evidence.inspect()
	return Serialization.deepCopy(records)
end

function Evidence.clear()
	table.clear(records)
	nextOrdinal = 0
end

return Evidence

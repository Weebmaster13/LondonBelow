--!strict

local Serialization = require(script.Parent.PersistenceSerialization)
local Types = require(script.Parent.PersistenceTypes)

local Evidence = {}
local history: { any } = {}

local function trim()
	while #history > Types.Limits.MaxEvidence do
		table.remove(history, 1)
	end
end

function Evidence.record(kind: string, detail: any?)
	table.insert(history, {
		kind = kind,
		detail = Serialization.diagnosticCopy(detail),
	})
	trim()
end

function Evidence.inspect()
	return {
		count = #history,
		last = history[#history],
		history = Serialization.deepCopy(history),
	}
end

function Evidence.clear()
	table.clear(history)
end

return Evidence

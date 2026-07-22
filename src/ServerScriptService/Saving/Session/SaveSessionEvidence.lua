--!strict

local Serialization = require(script.Parent.SaveSessionSerialization)
local Types = require(script.Parent.SaveSessionTypes)

local Evidence = {}
local history: { any } = {}

function Evidence.record(kind: string, detail: any?)
	table.insert(history, {
		kind = kind,
		detail = Serialization.deepCopy(detail),
	})
	while #history > Types.Limits.MaxEvidence do
		table.remove(history, 1)
	end
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

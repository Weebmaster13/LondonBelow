--!strict

local Evidence = require(script.Parent.PersistenceEvidence)
local Serialization = require(script.Parent.PersistenceSerialization)
local Types = require(script.Parent.PersistenceTypes)
local Validation = require(script.Parent.PersistenceValidation)

local Pipeline = {}
local history: { any } = {}

local function remember(record: any)
	table.insert(history, Serialization.deepCopy(record))
	while #history > Types.Limits.MaxResponseHistory do
		table.remove(history, 1)
	end
end

function Pipeline.validate(responseRecord: any): (boolean, string?, any?)
	local ok, reason = Validation.runtimeResponse(responseRecord)
	if not ok then
		Evidence.record("validation", { stage = "response", reason = reason })
		return false, reason, nil
	end
	remember(responseRecord)
	return true, nil, Serialization.deepCopy(responseRecord)
end

function Pipeline.inspect()
	return {
		responses = #history,
		lastResponse = history[#history],
		history = Serialization.deepCopy(history),
	}
end

function Pipeline.clear()
	table.clear(history)
end

return Pipeline

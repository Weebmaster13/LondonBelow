--!strict

local Evidence = require(script.Parent.SaveEvidence)
local Registry = require(script.Parent.SaveSchemaRegistry)
local Serialization = require(script.Parent.SaveSerialization)
local Types = require(script.Parent.SaveTypes)
local Validation = require(script.Parent.SaveValidation)

local Serializer = {}
local history: { any } = {}

local function remember(record: any)
	table.insert(history, Serialization.deepCopy(record))
	if #history > Types.Limits.MaxSerializationHistory then
		table.remove(history, 1)
	end
end

function Serializer.serialize(save: any): (boolean, string?, any?)
	local ok, reason = Validation.saveRecord(save)
	if not ok then
		Evidence.record("serializationRejected", { reason = reason })
		return false, reason, nil
	end
	if Registry.get(Types.Chapter0SchemaId) == nil then
		Evidence.record("serializationRejected", { reason = "missing save schema" })
		return false, "missing save schema", nil
	end
	for _, objective in ipairs(save.objectiveProgress) do
		if not Registry.hasObjective(Types.Chapter0SchemaId, objective.objectiveId) then
			return false, "unknown objective identifier", nil
		end
	end
	for _, checkpoint in ipairs(save.checkpointProgress) do
		if not Registry.hasCheckpoint(Types.Chapter0SchemaId, checkpoint.checkpointId) then
			return false, "unknown checkpoint identifier", nil
		end
	end
	local envelope = Serialization.freezeDeep(save)
	local stable = Serialization.stableEncode(envelope)
	remember({
		saveId = envelope.saveId,
		chapterId = envelope.chapterId,
		stableLength = #stable,
		objectiveCount = #envelope.objectiveProgress,
		checkpointCount = #envelope.checkpointProgress,
	})
	Evidence.record("serialization", {
		saveId = envelope.saveId,
		objectiveCount = #envelope.objectiveProgress,
		checkpointCount = #envelope.checkpointProgress,
	})
	return true, nil, {
		envelope = envelope,
		stable = stable,
	}
end

function Serializer.inspect()
	return {
		serializations = #history,
		lastSerialization = history[#history],
		history = Serialization.deepCopy(history),
	}
end

function Serializer.clear()
	table.clear(history)
end

return Serializer

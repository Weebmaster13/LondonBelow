--!strict

local Evidence = require(script.Parent.SaveEvidence)
local Migration = require(script.Parent.SaveMigrationRuntime)
local Registry = require(script.Parent.SaveSchemaRegistry)
local Serialization = require(script.Parent.SaveSerialization)
local Validation = require(script.Parent.SaveValidation)
local Types = require(script.Parent.SaveTypes)

local Deserializer = {}
local history: { any } = {}

local function remember(record: any)
	table.insert(history, Serialization.deepCopy(record))
	if #history > Types.Limits.MaxSerializationHistory then
		table.remove(history, 1)
	end
end

function Deserializer.deserialize(payload: any): (boolean, string?, any?)
	local migratedOk, migratedReason, migrated = Migration.migrate(payload)
	if not migratedOk then
		Evidence.record("deserializationRejected", { reason = migratedReason })
		return false, migratedReason, nil
	end
	local ok, reason = Validation.saveRecord(migrated)
	if not ok then
		Evidence.record("deserializationRejected", { reason = reason })
		return false, reason, nil
	end
	for _, objective in ipairs(migrated.objectiveProgress) do
		if not Registry.hasObjective(Types.Chapter0SchemaId, objective.objectiveId) then
			return false, "unknown objective identifier", nil
		end
	end
	for _, checkpoint in ipairs(migrated.checkpointProgress) do
		if not Registry.hasCheckpoint(Types.Chapter0SchemaId, checkpoint.checkpointId) then
			return false, "unknown checkpoint identifier", nil
		end
	end
	local restored = {
		saveId = migrated.saveId,
		schemaVersion = migrated.schemaVersion,
		migrationVersion = migrated.migrationVersion,
		chapterId = migrated.chapterId,
		objectiveProgress = Serialization.deepCopy(migrated.objectiveProgress),
		checkpointProgress = Serialization.deepCopy(migrated.checkpointProgress),
		runtimeMetadata = Serialization.deepCopy(migrated.runtimeMetadata or {}),
	}
	remember({
		saveId = restored.saveId,
		objectiveCount = #restored.objectiveProgress,
		checkpointCount = #restored.checkpointProgress,
	})
	Evidence.record("deserialization", {
		saveId = restored.saveId,
		objectiveCount = #restored.objectiveProgress,
		checkpointCount = #restored.checkpointProgress,
	})
	return true, nil, restored
end

function Deserializer.inspect()
	return {
		deserializations = #history,
		lastDeserialization = history[#history],
		history = Serialization.deepCopy(history),
	}
end

function Deserializer.clear()
	table.clear(history)
end

return Deserializer

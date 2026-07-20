--!strict

local Deserializer = require(script.Parent.SaveDeserializer)
local Evidence = require(script.Parent.SaveEvidence)
local Migration = require(script.Parent.SaveMigrationRuntime)
local Registry = require(script.Parent.SaveSchemaRegistry)
local Serializer = require(script.Parent.SaveSerializer)
local Serialization = require(script.Parent.SaveSerialization)
local Types = require(script.Parent.SaveTypes)

local Runtime = {}

local chapter0Objectives = {
	{
		objectiveId = "chapter0.home.objective.inspect_note",
		state = Types.PersistentObjectiveState.Completed,
		completionTimestamp = 1,
		revision = 1,
	},
	{
		objectiveId = "chapter0.home.objective.restore_power",
		state = Types.PersistentObjectiveState.Completed,
		completionTimestamp = 2,
		revision = 2,
	},
	{
		objectiveId = "chapter0.home.objective.open_front_door",
		state = Types.PersistentObjectiveState.Completed,
		completionTimestamp = 3,
		revision = 3,
	},
	{
		objectiveId = "chapter0.home.objective.leave_home",
		state = Types.PersistentObjectiveState.Active,
		completionTimestamp = nil,
		revision = 4,
	},
}

local chapter0Checkpoints = {
	{
		checkpointId = "chapter0.home.checkpoint.start",
		eligible = true,
		activated = true,
		revision = 1,
	},
	{
		checkpointId = "chapter0.home.checkpoint.power_restored",
		eligible = true,
		activated = true,
		revision = 2,
	},
	{
		checkpointId = "chapter0.home.checkpoint.exit_ready",
		eligible = true,
		activated = false,
		revision = 3,
	},
}

function Runtime.registerDefaultSchemas(): (boolean, string?)
	return Registry.registerChapter0Schema()
end

function Runtime.chapter0ValidationSave()
	return {
		saveId = "chapter0.home.validation.save",
		schemaVersion = Types.SchemaVersion,
		migrationVersion = Types.MigrationVersion,
		createdTimestamp = 1,
		updatedTimestamp = 4,
		chapterId = "chapter0.home",
		objectiveProgress = Serialization.deepCopy(chapter0Objectives),
		checkpointProgress = Serialization.deepCopy(chapter0Checkpoints),
		runtimeMetadata = {
			sourceRuntime = "Gameplay Flow Runtime",
			sourceAuthority = "server",
			containsRuntimeReferences = false,
		},
	}
end

function Runtime.serializeProgress(save: any)
	return Serializer.serialize(save)
end

function Runtime.deserializeProgress(save: any)
	return Deserializer.deserialize(save)
end

function Runtime.migrateSave(save: any)
	return Migration.migrate(save)
end

function Runtime.inspect()
	return {
		schemas = Registry.inspect(),
		serializer = Serializer.inspect(),
		deserializer = Deserializer.inspect(),
		migration = Migration.inspect(),
		evidence = Evidence.inspect(),
	}
end

function Runtime.clear()
	Registry.clear()
	Serializer.clear()
	Deserializer.clear()
	Migration.clear()
	Evidence.clear()
end

return Runtime

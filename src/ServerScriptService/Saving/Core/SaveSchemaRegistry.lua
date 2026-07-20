--!strict

local Serialization = require(script.Parent.SaveSerialization)
local Types = require(script.Parent.SaveTypes)

local Registry = {}
local schemasById: { [string]: any } = {}
local schemaOrder: { string } = {}

local chapter0Schema = {
	schemaId = Types.Chapter0SchemaId,
	schemaVersion = Types.SchemaVersion,
	migrationVersion = Types.MigrationVersion,
	chapterId = "chapter0.home",
	objectiveIds = {
		"chapter0.home.objective.inspect_note",
		"chapter0.home.objective.restore_power",
		"chapter0.home.objective.open_front_door",
		"chapter0.home.objective.leave_home",
	},
	checkpointIds = {
		"chapter0.home.checkpoint.start",
		"chapter0.home.checkpoint.power_restored",
		"chapter0.home.checkpoint.exit_ready",
	},
}

local function validId(value: any): boolean
	return type(value) == "string" and value ~= "" and #value <= 140
end

local function register(schema: any): (boolean, string?)
	if type(schema) ~= "table" then
		return false, "save schema must be a table"
	end
	if not validId(schema.schemaId) then
		return false, "schemaId is required"
	end
	if schemasById[schema.schemaId] ~= nil then
		return false, "duplicate save schema"
	end
	if #schemaOrder >= Types.Limits.MaxSaveSchemas then
		return false, "save schema limit reached"
	end
	schemasById[schema.schemaId] = Serialization.deepCopy(schema)
	table.freeze(schemasById[schema.schemaId])
	table.insert(schemaOrder, schema.schemaId)
	table.sort(schemaOrder)
	return true, nil
end

function Registry.registerChapter0Schema(): (boolean, string?)
	if schemasById[Types.Chapter0SchemaId] ~= nil then
		return true, nil
	end
	return register(chapter0Schema)
end

function Registry.get(schemaId: string): any?
	local schema = schemasById[schemaId]
	return if schema == nil then nil else Serialization.deepCopy(schema)
end

function Registry.hasObjective(schemaId: string, objectiveId: string): boolean
	local schema = schemasById[schemaId]
	if schema == nil then
		return false
	end
	for _, knownId in ipairs(schema.objectiveIds) do
		if knownId == objectiveId then
			return true
		end
	end
	return false
end

function Registry.hasCheckpoint(schemaId: string, checkpointId: string): boolean
	local schema = schemasById[schemaId]
	if schema == nil then
		return false
	end
	for _, knownId in ipairs(schema.checkpointIds) do
		if knownId == checkpointId then
			return true
		end
	end
	return false
end

function Registry.inspect()
	return {
		schemaCount = #schemaOrder,
		schemaIds = table.clone(schemaOrder),
		chapter0Schema = Registry.get(Types.Chapter0SchemaId),
	}
end

function Registry.clear()
	table.clear(schemasById)
	table.clear(schemaOrder)
end

return Registry

--!strict

local Evidence = require(script.Parent.SaveEvidence)
local Serialization = require(script.Parent.SaveSerialization)
local Types = require(script.Parent.SaveTypes)

local Migration = {}
local runs: { any } = {}

local function record(status: string, reason: string?)
	local run = {
		schemaVersion = Types.SchemaVersion,
		migrationVersion = Types.MigrationVersion,
		status = status,
		reason = reason,
	}
	table.insert(runs, run)
	if #runs > Types.Limits.MaxMigrationRuns then
		table.remove(runs, 1)
	end
	Evidence.record("migration", run)
end

function Migration.migrate(save: any): (boolean, string?, any?)
	if type(save) ~= "table" then
		record("Rejected", "save record must be a table")
		return false, "save record must be a table", nil
	end
	if save.schemaVersion == nil then
		record("Rejected", "missing schema version")
		return false, "missing schema version", nil
	end
	if save.migrationVersion == nil then
		record("Rejected", "missing migration version")
		return false, "missing migration version", nil
	end
	if save.schemaVersion ~= Types.SchemaVersion then
		record("Rejected", "unsupported schema version")
		return false, "unsupported schema version", nil
	end
	if save.migrationVersion ~= Types.MigrationVersion then
		record("Rejected", "unsupported migration version")
		return false, "unsupported migration version", nil
	end
	record("NoOp", nil)
	return true, nil, Serialization.deepCopy(save)
end

function Migration.inspect()
	return {
		migrationRuns = #runs,
		runs = Serialization.deepCopy(runs),
	}
end

function Migration.clear()
	table.clear(runs)
end

return Migration

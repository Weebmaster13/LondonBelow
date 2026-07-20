--!strict
-- Validation for server-owned Save / Journal / Identity runtime records.

local Serialization = require(script.Parent.SaveSerialization)
local Types = require(script.Parent.SaveTypes)

local Validation = {}

local FORBIDDEN_FIELDS = {
	"client",
	"remote",
	"remotes",
	"workspace",
	"instance",
	"ui",
	"dataStore",
	"cloudSave",
	"networking",
	"profileService",
	"analytics",
	"telemetry",
	"runtimeReference",
	"runtimeObject",
	"storyDialogue",
	"finalStory",
	"cutscene",
	"monsterAI",
	"horrorPacing",
	"temporaryPressure",
	"lighting",
	"audio",
}

local function validId(value: any): boolean
	return type(value) == "string" and value ~= "" and #value <= 140
end

local function forbidden(payload: any, depth: number): (boolean, string?)
	if type(payload) ~= "table" then
		return true, nil
	end
	if depth > Types.Limits.MaxPayloadDepth then
		return false, "save payload depth exceeds limit"
	end
	for _, field in ipairs(FORBIDDEN_FIELDS) do
		if payload[field] ~= nil then
			return false, "save payload contains forbidden field: " .. field
		end
	end
	for _, nested in pairs(payload) do
		local ok, reason = forbidden(nested, depth + 1)
		if not ok then
			return false, reason
		end
	end
	return true, nil
end

function Validation.isValidId(value: any): boolean
	return validId(value)
end

function Validation.safePayload(payload: any): (boolean, string?)
	local ok, reason = Serialization.validateSerializable(payload)
	if not ok then
		return false, reason
	end
	return forbidden(payload, 0)
end

function Validation.profile(definition: any): (boolean, string?)
	if type(definition) ~= "table" then
		return false, "profile definition must be a table"
	end
	if not validId(definition.profileId) then
		return false, "profileId is required"
	end
	if definition.userId ~= nil and type(definition.userId) ~= "number" then
		return false, "userId must be a number"
	end
	return Validation.safePayload(definition.metadata or {})
end

function Validation.checkpoint(profileId: string, checkpoint: any): (boolean, string?)
	if not validId(profileId) then
		return false, "profileId is required"
	end
	if type(checkpoint) ~= "table" then
		return false, "checkpoint must be a table"
	end
	if not validId(checkpoint.checkpointId) then
		return false, "checkpointId is required"
	end
	if checkpoint.chapterId ~= nil and not validId(checkpoint.chapterId) then
		return false, "chapterId is invalid"
	end
	return Validation.safePayload(checkpoint.state or {})
end

function Validation.journalEntry(profileId: string, entry: any): (boolean, string?)
	if not validId(profileId) then
		return false, "profileId is required"
	end
	if type(entry) ~= "table" then
		return false, "journal entry must be a table"
	end
	if not validId(entry.entryId) then
		return false, "entryId is required"
	end
	if entry.schemaKind ~= nil and not validId(entry.schemaKind) then
		return false, "schemaKind is invalid"
	end
	return Validation.safePayload(entry.metadata or {})
end

function Validation.memoryFragment(profileId: string, fragment: any): (boolean, string?)
	if not validId(profileId) then
		return false, "profileId is required"
	end
	if type(fragment) ~= "table" then
		return false, "memory fragment must be a table"
	end
	if not validId(fragment.fragmentId) then
		return false, "fragmentId is required"
	end
	return Validation.safePayload(fragment.metadata or {})
end

function Validation.identityDelta(profileId: string, amount: any): (boolean, string?)
	if not validId(profileId) then
		return false, "profileId is required"
	end
	if type(amount) ~= "number" or amount ~= amount then
		return false, "identity amount must be a number"
	end
	return true, nil
end

function Validation.replayState(profileId: string, replay: any): (boolean, string?)
	if not validId(profileId) then
		return false, "profileId is required"
	end
	if type(replay) ~= "table" then
		return false, "replay state must be a table"
	end
	if not validId(replay.replayId) then
		return false, "replayId is required"
	end
	return Validation.safePayload(replay.meaning or {})
end

local function validateExactFields(payload: any, allowed: { [string]: boolean }): (boolean, string?)
	for key in pairs(payload) do
		if type(key) ~= "string" or allowed[key] ~= true then
			return false, "unsupported save field: " .. tostring(key)
		end
	end
	return true, nil
end

local function validateObjectiveState(state: any): boolean
	return type(state) == "string" and Types.PersistentObjectiveState[state] ~= nil
end

function Validation.objectiveProgress(record: any): (boolean, string?)
	if type(record) ~= "table" then
		return false, "objective progress must be a table"
	end
	local exactOk, exactReason = validateExactFields(record, {
		objectiveId = true,
		state = true,
		completionTimestamp = true,
		revision = true,
	})
	if not exactOk then
		return false, exactReason
	end
	if not validId(record.objectiveId) then
		return false, "objectiveId is required"
	end
	if not validateObjectiveState(record.state) then
		return false, "invalid objective state"
	end
	if record.completionTimestamp ~= nil and type(record.completionTimestamp) ~= "number" then
		return false, "completionTimestamp must be number or nil"
	end
	if type(record.revision) ~= "number" or record.revision < 0 then
		return false, "objective revision is invalid"
	end
	return true, nil
end

function Validation.checkpointProgress(record: any): (boolean, string?)
	if type(record) ~= "table" then
		return false, "checkpoint progress must be a table"
	end
	local exactOk, exactReason = validateExactFields(record, {
		checkpointId = true,
		eligible = true,
		activated = true,
		revision = true,
	})
	if not exactOk then
		return false, exactReason
	end
	if not validId(record.checkpointId) then
		return false, "checkpointId is required"
	end
	if type(record.eligible) ~= "boolean" or type(record.activated) ~= "boolean" then
		return false, "checkpoint flags must be boolean"
	end
	if type(record.revision) ~= "number" or record.revision < 0 then
		return false, "checkpoint revision is invalid"
	end
	return true, nil
end

function Validation.saveRecord(save: any): (boolean, string?)
	if type(save) ~= "table" then
		return false, "save record must be a table"
	end
	local exactOk, exactReason = validateExactFields(save, {
		saveId = true,
		schemaVersion = true,
		migrationVersion = true,
		createdTimestamp = true,
		updatedTimestamp = true,
		chapterId = true,
		objectiveProgress = true,
		checkpointProgress = true,
		runtimeMetadata = true,
	})
	if not exactOk then
		return false, exactReason
	end
	if not validId(save.saveId) or not validId(save.chapterId) then
		return false, "saveId and chapterId are required"
	end
	if save.schemaVersion ~= Types.SchemaVersion then
		return false, "unsupported schema version"
	end
	if save.migrationVersion ~= Types.MigrationVersion then
		return false, "unsupported migration version"
	end
	if type(save.createdTimestamp) ~= "number" or type(save.updatedTimestamp) ~= "number" then
		return false, "save timestamps are required"
	end
	if type(save.objectiveProgress) ~= "table" then
		return false, "objectiveProgress must be an array"
	end
	if type(save.checkpointProgress) ~= "table" then
		return false, "checkpointProgress must be an array"
	end
	if #save.objectiveProgress > Types.Limits.MaxObjectivesPerSave then
		return false, "objective progress exceeds limit"
	end
	if #save.checkpointProgress > Types.Limits.MaxCheckpointsPerSave then
		return false, "checkpoint progress exceeds limit"
	end
	local objectiveIds = {}
	for _, objective in ipairs(save.objectiveProgress) do
		local ok, reason = Validation.objectiveProgress(objective)
		if not ok then
			return false, reason
		end
		if objectiveIds[objective.objectiveId] then
			return false, "duplicate objective"
		end
		objectiveIds[objective.objectiveId] = true
	end
	local checkpointIds = {}
	for _, checkpoint in ipairs(save.checkpointProgress) do
		local ok, reason = Validation.checkpointProgress(checkpoint)
		if not ok then
			return false, reason
		end
		if checkpointIds[checkpoint.checkpointId] then
			return false, "duplicate checkpoint"
		end
		checkpointIds[checkpoint.checkpointId] = true
	end
	return Validation.safePayload(save.runtimeMetadata or {})
end

function Validation.validate(): (boolean, string?)
	if Types.Mode ~= "ServerAuthoritativeFoundation" then
		return false, "Save runtime must remain server-authoritative foundation mode"
	end
	if Types.Limits.MaxProfiles <= 0 or Types.Limits.MaxPayloadNodes <= 0 then
		return false, "Save runtime limits must be positive"
	end
	return true, nil
end

return Validation

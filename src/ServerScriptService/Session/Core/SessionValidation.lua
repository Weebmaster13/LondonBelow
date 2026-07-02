--!strict
-- Validation boundary for server-owned session schemas.

local Serialization = require(script.Parent.SessionSerialization)
local Types = require(script.Parent.SessionTypes)

local Validation = {}

local FORBIDDEN_FIELDS = {
	"audio",
	"camera",
	"chapter",
	"chapter0",
	"chapter1",
	"client",
	"cutscene",
	"dialogue",
	"execute",
	"horrorPacing",
	"instance",
	"lighting",
	"lobbyUi",
	"matchmakingExecution",
	"monsterAI",
	"movement",
	"narrative",
	"partyGameplay",
	"remote",
	"save",
	"savePersistence",
	"spawnPlayer",
	"story",
	"teleport",
	"teleportExecution",
	"ui",
	"workspace",
}

local FORBIDDEN_LOOKUP: { [string]: boolean } = {}

for _, field in ipairs(FORBIDDEN_FIELDS) do
	FORBIDDEN_LOOKUP[string.lower(field)] = true
end

local function validId(value: any): boolean
	return type(value) == "string"
		and value ~= ""
		and #value <= 150
		and string.match(value, "^[%w%._%-:]+$") ~= nil
end

local function supportedSchemaType(value: any): boolean
	for _, schemaType in pairs(Types.SchemaType) do
		if value == schemaType then
			return true
		end
	end
	return false
end

local function forbidden(payload: any, depth: number): (boolean, string?)
	if type(payload) ~= "table" then
		return true, nil
	end
	if depth > Types.Limits.MaxPayloadDepth then
		return false, "session payload depth exceeds limit"
	end
	for key in pairs(payload) do
		if type(key) == "string" and FORBIDDEN_LOOKUP[string.lower(key)] == true then
			return false, "session payload contains forbidden field: " .. key
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

local function validateTags(tags: any): (boolean, string?)
	if tags == nil then
		return true, nil
	end
	if type(tags) ~= "table" then
		return false, "tags must be a table"
	end
	if #tags > Types.Limits.MaxTags then
		return false, "tag count exceeds limit"
	end
	for _, tag in ipairs(tags) do
		if not validId(tag) then
			return false, "tag is invalid"
		end
		if FORBIDDEN_LOOKUP[string.lower(tag)] == true then
			return false, "tag uses forbidden ownership domain: " .. tag
		end
	end
	return true, nil
end

function Validation.safePayload(payload: any): (boolean, string?)
	local ok, reason = Serialization.validateSerializable(payload)
	if not ok then
		return false, reason
	end
	return forbidden(payload, 0)
end

function Validation.id(value: any): boolean
	return validId(value)
end

function Validation.session(schema: any): (boolean, string?)
	if type(schema) ~= "table" then
		return false, "session schema must be a table"
	end
	local safe, reason = Validation.safePayload(schema)
	if not safe then
		return false, reason
	end
	if not validId(schema.sessionId) or not validId(schema.ownerSystem) then
		return false, "session identity fields are invalid"
	end
	if not supportedSchemaType(schema.sessionType) then
		return false, "unsupported session type"
	end
	if schema.schemaType ~= nil and not supportedSchemaType(schema.schemaType) then
		return false, "unsupported session schema type"
	end
	return validateTags(schema.tags)
end

function Validation.playerSession(record: any): (boolean, string?)
	if type(record) ~= "table" then
		return false, "player session record must be a table"
	end
	local safe, reason = Validation.safePayload(record)
	if not safe then
		return false, reason
	end
	if not validId(record.playerSessionId) or not validId(record.sessionId) then
		return false, "player session identity fields are invalid"
	end
	if record.schemaType ~= nil and not supportedSchemaType(record.schemaType) then
		return false, "unsupported player session schema type"
	end
	return validateTags(record.tags)
end

function Validation.party(schema: any): (boolean, string?)
	if type(schema) ~= "table" then
		return false, "malformed party schema"
	end
	local safe, reason = Validation.safePayload(schema)
	if not safe then
		return false, reason
	end
	if not validId(schema.partyId) or not validId(schema.sessionId) then
		return false, "malformed party schema"
	end
	if schema.schemaType ~= nil and not supportedSchemaType(schema.schemaType) then
		return false, "unsupported party schema type"
	end
	return validateTags(schema.tags)
end

function Validation.readiness(record: any): (boolean, string?)
	if type(record) ~= "table" then
		return false, "malformed readiness record"
	end
	local safe, reason = Validation.safePayload(record)
	if not safe then
		return false, reason
	end
	if not validId(record.readinessId) or not validId(record.sessionId) then
		return false, "malformed readiness record"
	end
	if type(record.ready) ~= "boolean" then
		return false, "malformed readiness record"
	end
	if record.schemaType ~= nil and not supportedSchemaType(record.schemaType) then
		return false, "unsupported readiness schema type"
	end
	return validateTags(record.tags)
end

function Validation.lifecycle(record: any): (boolean, string?)
	if type(record) ~= "table" then
		return false, "malformed lifecycle record"
	end
	local safe, reason = Validation.safePayload(record)
	if not safe then
		return false, reason
	end
	if
		not validId(record.lifecycleId)
		or not validId(record.sessionId)
		or not validId(record.lifecycleState)
	then
		return false, "malformed lifecycle record"
	end
	if record.schemaType ~= nil and not supportedSchemaType(record.schemaType) then
		return false, "unsupported lifecycle schema type"
	end
	return validateTags(record.tags)
end

function Validation.joinLeave(record: any): (boolean, string?)
	if type(record) ~= "table" then
		return false, "malformed join/leave record"
	end
	local safe, reason = Validation.safePayload(record)
	if not safe then
		return false, reason
	end
	if
		not validId(record.joinLeaveId)
		or not validId(record.sessionId)
		or not validId(record.action)
	then
		return false, "malformed join/leave record"
	end
	if record.action ~= "Join" and record.action ~= "Leave" then
		return false, "malformed join/leave record"
	end
	if record.schemaType ~= nil and not supportedSchemaType(record.schemaType) then
		return false, "unsupported join/leave schema type"
	end
	return validateTags(record.tags)
end

function Validation.validate(): (boolean, string?)
	if Types.Mode ~= "ServerAuthoritativeSessionSchemaRuntime" then
		return false, "Session Runtime must remain server-authoritative schema runtime"
	end
	return true, nil
end

return Validation

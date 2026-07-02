--!strict
-- Validation boundary for server-owned physical object schemas.

local Serialization = require(script.Parent.PhysicalSerialization)
local Types = require(script.Parent.PhysicalTypes)

local Validation = {}

local FORBIDDEN_FIELDS = {
	"animation",
	"audio",
	"chapter",
	"chapter0",
	"chapter1",
	"client",
	"combat",
	"cutscene",
	"damage",
	"dialogue",
	"finalStory",
	"function",
	"horror",
	"horrorPacing",
	"instance",
	"lighting",
	"monster",
	"monsterAI",
	"move",
	"movement",
	"navigation",
	"path",
	"pathfinding",
	"physics",
	"physicsExecution",
	"play",
	"remote",
	"save",
	"sound",
	"spawn",
	"story",
	"ui",
	"workspace",
}

local function validId(value: any): boolean
	return type(value) == "string"
		and value ~= ""
		and #value <= 140
		and string.match(value, "^[%w%._%-:]+$") ~= nil
end

local function supportedObjectType(value: any): boolean
	if type(value) ~= "string" then
		return false
	end
	for _, objectType in pairs(Types.ObjectType) do
		if value == objectType then
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
		return false, "physical payload depth exceeds limit"
	end
	for _, field in ipairs(FORBIDDEN_FIELDS) do
		if payload[field] ~= nil then
			return false, "physical payload contains forbidden field: " .. field
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

function Validation.objectSchema(schema: any): (boolean, string?)
	if type(schema) ~= "table" then
		return false, "physical object schema must be a table"
	end
	local safe, safeReason = Validation.safePayload(schema)
	if not safe then
		return false, safeReason
	end
	if not validId(schema.physicalObjectId) then
		return false, "physicalObjectId is required"
	end
	if not supportedObjectType(schema.objectType) then
		return false, "objectType is invalid"
	end
	if not validId(schema.schemaVersion) then
		return false, "schemaVersion is required"
	end
	if not validId(schema.ownerSystem) then
		return false, "ownerSystem is required"
	end
	if schema.state ~= nil and type(schema.state) ~= "table" then
		return false, "state must be a table"
	end
	if schema.reservationState ~= nil and type(schema.reservationState) ~= "table" then
		return false, "reservationState must be a table"
	end
	if schema.transformSchema ~= nil and type(schema.transformSchema) ~= "table" then
		return false, "transformSchema must be a table"
	end
	local tagsOk, tagsReason = validateTags(schema.tags)
	if not tagsOk then
		return false, tagsReason
	end
	if schema.metadata ~= nil and type(schema.metadata) ~= "table" then
		return false, "metadata must be a table"
	end
	return true, nil
end

function Validation.ownership(objectId: any, ownerSystem: any): (boolean, string?)
	if not validId(objectId) then
		return false, "physicalObjectId is required"
	end
	if not validId(ownerSystem) then
		return false, "ownerSystem is invalid"
	end
	return true, nil
end

function Validation.reservation(
	objectId: any,
	reservationId: any,
	ownerSystem: any
): (boolean, string?)
	if not validId(objectId) then
		return false, "physicalObjectId is required"
	end
	if not validId(reservationId) then
		return false, "reservationId is required"
	end
	if not validId(ownerSystem) then
		return false, "ownerSystem is invalid"
	end
	return true, nil
end

function Validation.validate(): (boolean, string?)
	if Types.Mode ~= "ServerAuthoritativePhysicalSchemaRuntime" then
		return false, "Physical Runtime must remain server-authoritative schema runtime"
	end
	return true, nil
end

return Validation

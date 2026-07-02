--!strict
-- Validation boundary for server-owned interaction schemas.

local Serialization = require(script.Parent.InteractionSerialization)
local Types = require(script.Parent.InteractionTypes)

local Validation = {}

local FORBIDDEN_FIELDS = {
	"animation",
	"audio",
	"chapter",
	"chapter0",
	"chapter1",
	"client",
	"completePuzzle",
	"cutscene",
	"dialogue",
	"doorExecution",
	"drawerExecution",
	"execute",
	"horrorPacing",
	"instance",
	"inventory",
	"inventoryExecution",
	"lighting",
	"monsterAI",
	"movement",
	"narrative",
	"pathfinding",
	"physics",
	"pickupExecution",
	"puzzleCompletion",
	"remote",
	"save",
	"story",
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
		and #value <= 140
		and string.match(value, "^[%w%._%-:]+$") ~= nil
end

local function supportedInteractionType(value: any): boolean
	for _, interactionType in pairs(Types.InteractionType) do
		if value == interactionType then
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
		return false, "interaction payload depth exceeds limit"
	end
	for key in pairs(payload) do
		if type(key) == "string" and FORBIDDEN_LOOKUP[string.lower(key)] == true then
			return false, "interaction payload contains forbidden field: " .. key
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

function Validation.cooldown(cooldown: any): (boolean, string?)
	if cooldown == nil then
		return true, nil
	end
	if type(cooldown) ~= "table" then
		return false, "cooldown must be a table"
	end
	local safe, reason = Validation.safePayload(cooldown)
	if not safe then
		return false, reason
	end
	if cooldown.seconds ~= nil then
		if type(cooldown.seconds) ~= "number" or cooldown.seconds ~= cooldown.seconds then
			return false, "cooldown seconds must be a number"
		end
		if cooldown.seconds < 0 or cooldown.seconds > Types.Limits.MaxCooldownSeconds then
			return false, "cooldown seconds outside bounds"
		end
	end
	return true, nil
end

function Validation.lock(lockState: any): (boolean, string?)
	if lockState == nil then
		return true, nil
	end
	if type(lockState) ~= "table" then
		return false, "lockState must be a table"
	end
	return Validation.safePayload(lockState)
end

function Validation.schema(schema: any): (boolean, string?)
	if type(schema) ~= "table" then
		return false, "interaction schema must be a table"
	end
	local safe, safeReason = Validation.safePayload(schema)
	if not safe then
		return false, safeReason
	end
	if not validId(schema.interactionId) then
		return false, "interactionId is required"
	end
	if not validId(schema.physicalObjectId) then
		return false, "physicalObjectId is required"
	end
	if not supportedInteractionType(schema.interactionType) then
		return false, "unsupported interaction type"
	end
	if not validId(schema.ownerSystem) then
		return false, "ownerSystem is required"
	end
	if schema.eligibility ~= nil and type(schema.eligibility) ~= "table" then
		return false, "eligibility must be a table"
	end
	if schema.requiredState ~= nil and type(schema.requiredState) ~= "table" then
		return false, "requiredState must be a table"
	end
	local cooldownOk, cooldownReason = Validation.cooldown(schema.cooldown)
	if not cooldownOk then
		return false, cooldownReason
	end
	local lockOk, lockReason = Validation.lock(schema.lockState)
	if not lockOk then
		return false, lockReason
	end
	if schema.metadata ~= nil and type(schema.metadata) ~= "table" then
		return false, "metadata must be a table"
	end
	if schema.context ~= nil and type(schema.context) ~= "table" then
		return false, "context must be a table"
	end
	local tagsOk, tagsReason = validateTags(schema.tags)
	if not tagsOk then
		return false, tagsReason
	end
	return true, nil
end

function Validation.validate(): (boolean, string?)
	if Types.Mode ~= "ServerAuthoritativeInteractionSchemaRuntime" then
		return false, "Interaction Runtime must remain server-authoritative schema runtime"
	end
	return true, nil
end

return Validation

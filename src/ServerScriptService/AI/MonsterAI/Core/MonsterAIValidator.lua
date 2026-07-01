--!strict
-- Validation for approved Monster AI execution intents.

local Serialization = require(script.Parent.MonsterAISerialization)
local Types = require(script.Parent.MonsterAITypes)

local Validator = {}

local FORBIDDEN_FIELDS = {
	"workspace",
	"instance",
	"humanoid",
	"model",
	"part",
	"path",
	"pathfinding",
	"navigationPath",
	"moveTo",
	"cframe",
	"position",
	"damage",
	"attack",
	"animation",
	"sound",
	"lighting",
	"remote",
	"client",
	"ui",
	"jumpscare",
}

local function validId(value: any): boolean
	return type(value) == "string" and value ~= "" and #value <= 140
end

local function checkForbidden(payload: any, depth: number): (boolean, string?)
	if type(payload) ~= "table" then
		return true, nil
	end
	if depth > Types.Limits.MaxContextDepth then
		return false, "Monster AI payload depth exceeds limit"
	end
	for _, field in ipairs(FORBIDDEN_FIELDS) do
		if payload[field] ~= nil then
			return false, "Monster AI request includes forbidden execution field: " .. field
		end
	end
	for _, nested in pairs(payload) do
		local ok, reason = checkForbidden(nested, depth + 1)
		if not ok then
			return false, reason
		end
	end
	return true, nil
end

function Validator.isValidId(value: any): boolean
	return validId(value)
end

function Validator.validateDefinition(definition: any): (boolean, string?)
	if type(definition) ~= "table" then
		return false, "monster AI definition must be a table"
	end
	if not validId(definition.monsterId) then
		return false, "monsterId is required"
	end
	if not validId(definition.archetype) then
		return false, "archetype is required"
	end
	if not validId(definition.ownerSystem) then
		return false, "ownerSystem is required"
	end
	return Validator.validateNoExecutionLeakage(definition)
end

function Validator.validateNoExecutionLeakage(payload: any): (boolean, string?)
	local serializable, serializationReason = Serialization.validateSerializable(payload)
	if not serializable then
		return false, serializationReason
	end
	return checkForbidden(payload, 0)
end

function Validator.validateIntent(rawIntent: any, currentTime: number): (boolean, string?)
	if type(rawIntent) ~= "table" then
		return false, "intent must be a table"
	end
	if not validId(rawIntent.intentId) then
		return false, "intentId is required"
	end
	if not validId(rawIntent.monsterId) then
		return false, "monsterId is required"
	end
	if Types.SupportedIntentKinds[rawIntent.intentKind] ~= true then
		return false, "intentKind is not supported"
	end
	if not validId(rawIntent.sourceSystem) then
		return false, "sourceSystem is required"
	end
	if not validId(rawIntent.approvedBy) or not validId(rawIntent.approvalId) then
		return false, "Director approval is required"
	end
	if type(rawIntent.priority) ~= "number" or rawIntent.priority ~= rawIntent.priority then
		return false, "priority must be a number"
	end
	if rawIntent.priority < 0 or rawIntent.priority > 100 then
		return false, "priority must be between 0 and 100"
	end
	if type(rawIntent.createdAt) ~= "number" or rawIntent.createdAt < 0 then
		return false, "createdAt must be a non-negative number"
	end
	if type(rawIntent.expiresAt) ~= "number" or rawIntent.expiresAt <= currentTime then
		return false, "intent is expired"
	end
	if rawIntent.expiresAt < rawIntent.createdAt then
		return false, "expiresAt cannot be before createdAt"
	end
	return Validator.validateNoExecutionLeakage(rawIntent)
end

function Validator.validate(): (boolean, string?)
	if Types.ExecutionMode ~= "DryRunOnly" then
		return false, "Monster AI execution foundation must remain DryRunOnly"
	end
	if Types.Limits.MaxMonsters <= 0 or Types.Limits.MaxIntentHistory <= 0 then
		return false, "Monster AI limits must be positive"
	end
	return true, nil
end

return Validator

--!strict
-- Validation boundary for all public Living Cognition APIs.

local Config = require(script.Parent.LivingCognitionConfiguration)
local Serialization = require(script.Parent.LivingCognitionSerialization)

local Validation = {}

local function validId(value: any): boolean
	return type(value) == "string" and value ~= "" and #value <= 140
end

function Validation.isValidId(value: any): boolean
	return validId(value)
end

function Validation.confidence(value: any): (boolean, string?)
	if type(value) ~= "number" or value ~= value then
		return false, "confidence must be a number"
	end
	if value < 0 or value > 1 then
		return false, "confidence must be between 0 and 1"
	end
	return true, nil
end

function Validation.timestamp(value: any): (boolean, string?)
	if type(value) ~= "number" or value < 0 then
		return false, "timestamp must be a non-negative number"
	end
	return true, nil
end

local function checkForbiddenFields(payload: any, depth: number): (boolean, string?)
	if type(payload) ~= "table" then
		return true, nil
	end
	if depth > Config.MaxPayloadDepth then
		return false, "payload depth exceeds cognition validation limit"
	end
	for _, forbidden in ipairs(Config.ForbiddenFields) do
		if payload[forbidden] ~= nil then
			return false, "cognition payload contains forbidden execution field: " .. forbidden
		end
	end
	for _, nested in pairs(payload) do
		local ok, reason = checkForbiddenFields(nested, depth + 1)
		if not ok then
			return false, reason
		end
	end
	return true, nil
end

function Validation.noExecutionLeakage(payload: any): (boolean, string?)
	local serializable, serializationReason = Serialization.validateSerializable(payload)
	if not serializable then
		return false, serializationReason
	end
	return checkForbiddenFields(payload, 0)
end

function Validation.entity(definition: any): (boolean, string?)
	if type(definition) ~= "table" then
		return false, "entity definition must be a table"
	end
	if not validId(definition.entityId) then
		return false, "entityId is required"
	end
	if not validId(definition.entityKind) then
		return false, "entityKind is required"
	end
	if not validId(definition.ownerSystem) then
		return false, "ownerSystem is required"
	end
	return Validation.noExecutionLeakage(definition)
end

function Validation.observation(observation: any): (boolean, string?)
	if type(observation) ~= "table" then
		return false, "observation must be a table"
	end
	for _, key in ipairs({ "observationId", "entityId", "sourceSystem" }) do
		if not validId(observation[key]) then
			return false, key .. " is required"
		end
	end
	local confidenceOk, confidenceReason = Validation.confidence(observation.confidence)
	if not confidenceOk then
		return false, confidenceReason
	end
	local observedOk, observedReason = Validation.timestamp(observation.observedAt)
	if not observedOk then
		return false, observedReason
	end
	return Validation.noExecutionLeakage(observation.payload)
end

function Validation.thoughtTransition(fromState: string, toState: string): (boolean, string?)
	if
		Config.ValidThoughtStates[fromState] ~= true
		or Config.ValidThoughtStates[toState] ~= true
	then
		return false, "invalid thought state"
	end
	if fromState == "Archived" and toState ~= "Resurrected" then
		return false, "archived thoughts can only resurrect"
	end
	return true, nil
end

function Validation.validate(): (boolean, string?)
	if Config.Mode ~= "CognitionOnly" then
		return false, "Living Cognition must remain CognitionOnly"
	end
	return true, nil
end

return Validation

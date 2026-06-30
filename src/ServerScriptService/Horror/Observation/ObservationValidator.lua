--!strict
--[[
	Defensive validation for Observation Engine intake.

	Owns rejecting malformed IDs, unknown types, unsafe metadata, impossible
	timestamps, invalid player references, and corrupted payloads.

	Does not own enrichment, storage, pattern recognition, or interpretation.
	Validation must stay boring and strict: unsafe observations do not proceed.
]]

local Players = game:GetService("Players")

local ObservationConfig = require(script.Parent.ObservationConfig)
local ObservationRegistry = require(script.Parent.ObservationRegistry)
local Types = require(script.Parent.ObservationTypes)

local ObservationValidator = {}

type ObservationInput = Types.ObservationInput
type ValidationResult = Types.ValidationResult

local function result(ok: boolean, code: string, message: string): ValidationResult
	return {
		ok = ok,
		code = code,
		message = message,
	}
end

local function validateMetadataValue(value: any, depth: number): boolean
	if depth > 2 then
		return false
	end

	local valueType = typeof(value)

	if valueType == "string" then
		return #value <= ObservationConfig.MaxStringLength
	elseif valueType == "number" then
		return value == value and math.abs(value) < 1000000
	elseif valueType == "boolean" or value == nil then
		return true
	elseif valueType == "table" then
		local count = 0

		for key, child in pairs(value) do
			count += 1

			if count > ObservationConfig.MaxArrayItems then
				return false
			end

			if type(key) ~= "string" and type(key) ~= "number" then
				return false
			end

			if not validateMetadataValue(child, depth + 1) then
				return false
			end
		end

		return true
	end

	return false
end

function ObservationValidator.validate(
	input: ObservationInput
): (ValidationResult, Types.ObservationDefinition?)
	if type(input) ~= "table" then
		return result(false, "INVALID_PAYLOAD", "Observation payload must be a table."), nil
	end

	if type(input.id) ~= "string" or input.id == "" then
		return result(false, "INVALID_ID", "Observation id is required."), nil
	end

	local definition = ObservationRegistry.getUnsafe(input.id)

	if definition == nil then
		return result(false, "UNKNOWN_ID", "Observation id is not registered: " .. input.id), nil
	end

	if input.player ~= nil then
		if typeof(input.player) ~= "Instance" or not (input.player :: Instance):IsA("Player") then
			return result(false, "INVALID_PLAYER", "Observation player must be a Player."), nil
		end

		if Players:GetPlayerByUserId(input.player.UserId) ~= input.player then
			return result(false, "STALE_PLAYER", "Observation player is not active in this server."),
				nil
		end
	end

	if input.amount ~= nil then
		if type(input.amount) ~= "number" or input.amount ~= input.amount then
			return result(false, "INVALID_AMOUNT", "Observation amount must be numeric."), nil
		end

		if math.abs(input.amount) > ObservationConfig.MaxObservationAmount then
			return result(false, "AMOUNT_TOO_LARGE", "Observation amount is too large."), nil
		end
	end

	local currentTime = os.clock()

	if input.at ~= nil then
		if type(input.at) ~= "number" or input.at ~= input.at then
			return result(false, "INVALID_TIMESTAMP", "Observation timestamp must be numeric."), nil
		end

		if input.at > currentTime + ObservationConfig.MaxFutureTimestampSeconds then
			return result(
				false,
				"FUTURE_TIMESTAMP",
				"Observation timestamp is too far in the future."
			),
				nil
		end

		if input.at < currentTime - ObservationConfig.MaxPastTimestampSeconds then
			return result(false, "STALE_TIMESTAMP", "Observation timestamp is too old."), nil
		end
	end

	if input.metadata ~= nil then
		if type(input.metadata) ~= "table" then
			return result(false, "INVALID_METADATA", "Observation metadata must be a table."), nil
		end

		local keyCount = 0

		for key, value in pairs(input.metadata) do
			keyCount += 1

			if keyCount > ObservationConfig.MaxMetadataKeys then
				return result(
					false,
					"METADATA_TOO_LARGE",
					"Observation metadata has too many keys."
				),
					nil
			end

			if type(key) ~= "string" or key == "" or #key > ObservationConfig.MaxStringLength then
				return result(false, "INVALID_METADATA_KEY", "Observation metadata key is invalid."),
					nil
			end

			if not validateMetadataValue(value, 0) then
				return result(
					false,
					"INVALID_METADATA_VALUE",
					"Observation metadata value is invalid."
				),
					nil
			end
		end
	end

	return result(true, "OK", "Observation accepted."), definition
end

function ObservationValidator.validateRegistry(): (boolean, string?)
	return ObservationRegistry.validate()
end

return ObservationValidator

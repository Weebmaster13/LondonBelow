--!strict
-- Validation boundary for server-owned Accessibility Runtime schemas.

local Serialization = require(script.Parent.AccessibilitySerialization)
local Types = require(script.Parent.AccessibilityTypes)

local Validation = {}

local FORBIDDEN_FIELDS = {
	"audioExecution",
	"cameraExecution",
	"chapter",
	"chapter0",
	"chapter1",
	"client",
	"cutscene",
	"dialogue",
	"execute",
	"finalUi",
	"gameplayExecution",
	"inputRemappingExecution",
	"lightingExecution",
	"remote",
	"story",
	"ui",
	"userInputExecution",
	"vfxExecution",
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

local function forbidden(payload: any, depth: number): (boolean, string?)
	if type(payload) ~= "table" then
		return true, nil
	end
	if depth > Types.Limits.MaxPayloadDepth then
		return false, "Accessibility Runtime payload depth exceeds limit"
	end
	for key in pairs(payload) do
		if type(key) == "string" and FORBIDDEN_LOOKUP[string.lower(key)] == true then
			return false, "Accessibility Runtime payload contains forbidden field: " .. key
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

function Validation.setting(schema: any): (boolean, string?)
	if type(schema) ~= "table" then
		return false, "accessibility setting schema must be a table"
	end
	local safe, reason = Validation.safePayload(schema)
	if not safe then
		return false, reason
	end
	if not validId(schema.settingId) or not validId(schema.ownerSystem) then
		return false, "accessibility setting identity fields are invalid"
	end
	if
		schema.schemaType ~= nil
		and schema.schemaType ~= Types.SchemaType.AccessibilitySettingsSchema
	then
		return false, "unsupported accessibility setting schema type"
	end
	return validateTags(schema.tags)
end

function Validation.visual(schema: any): (boolean, string?)
	if type(schema) ~= "table" then
		return false, "visual safety rule schema must be a table"
	end
	local safe, reason = Validation.safePayload(schema)
	if not safe then
		return false, reason
	end
	if not validId(schema.visualId) or not validId(schema.ownerSystem) then
		return false, "visual safety rule identity fields are invalid"
	end
	if
		schema.schemaType ~= nil
		and schema.schemaType ~= Types.SchemaType.AccessibilityVisualSchema
	then
		return false, "unsupported visual safety rule schema type"
	end
	return validateTags(schema.tags)
end

function Validation.audio(schema: any): (boolean, string?)
	if type(schema) ~= "table" then
		return false, "audio safety rule must be a table"
	end
	local safe, reason = Validation.safePayload(schema)
	if not safe then
		return false, reason
	end
	if not validId(schema.audioId) or not validId(schema.ownerSystem) then
		return false, "audio safety rule identity fields are invalid"
	end
	if
		schema.schemaType ~= nil
		and schema.schemaType ~= Types.SchemaType.AccessibilityAudioSchema
	then
		return false, "unsupported audio safety rule type"
	end
	return validateTags(schema.tags)
end

function Validation.input(schema: any): (boolean, string?)
	if type(schema) ~= "table" then
		return false, "input assist schema must be a table"
	end
	local safe, reason = Validation.safePayload(schema)
	if not safe then
		return false, reason
	end
	if not validId(schema.inputId) or not validId(schema.ownerSystem) then
		return false, "input assist schema identity fields are invalid"
	end
	if
		schema.schemaType ~= nil
		and schema.schemaType ~= Types.SchemaType.AccessibilityInputSchema
	then
		return false, "unsupported input assist schema type"
	end
	return validateTags(schema.tags)
end

function Validation.motion(schema: any): (boolean, string?)
	if type(schema) ~= "table" then
		return false, "malformed motion comfort schema"
	end
	local safe, reason = Validation.safePayload(schema)
	if not safe then
		return false, reason
	end
	if not validId(schema.motionId) or not validId(schema.ownerSystem) then
		return false, "malformed motion comfort schema"
	end
	if
		schema.schemaType ~= nil
		and schema.schemaType ~= Types.SchemaType.AccessibilityMotionSchema
	then
		return false, "unsupported motion comfort schema type"
	end
	return validateTags(schema.tags)
end

function Validation.readability(record: any): (boolean, string?)
	if type(record) ~= "table" then
		return false, "malformed readability schema"
	end
	local safe, reason = Validation.safePayload(record)
	if not safe then
		return false, reason
	end
	if not validId(record.readabilityId) or not validId(record.ownerSystem) then
		return false, "malformed readability schema"
	end
	if
		record.schemaType ~= nil
		and record.schemaType ~= Types.SchemaType.AccessibilityReadabilitySchema
	then
		return false, "unsupported readability schema type"
	end
	return validateTags(record.tags)
end

function Validation.contentWarning(record: any): (boolean, string?)
	if type(record) ~= "table" then
		return false, "malformed content warning schema"
	end
	local safe, reason = Validation.safePayload(record)
	if not safe then
		return false, reason
	end
	if not validId(record.contentWarningId) or not validId(record.ownerSystem) then
		return false, "malformed content warning schema"
	end
	if
		record.schemaType ~= nil
		and record.schemaType ~= Types.SchemaType.AccessibilityContentWarningSchema
	then
		return false, "unsupported content warning schema type"
	end
	return validateTags(record.tags)
end

function Validation.validate(): (boolean, string?)
	if Types.Mode ~= "ServerAuthoritativeAccessibilitySchemaRuntime" then
		return false, "Accessibility Runtime must remain server-authoritative schema runtime"
	end
	return true, nil
end

return Validation

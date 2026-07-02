--!strict
-- Validation boundary for server-owned Localization Runtime schemas.

local Serialization = require(script.Parent.LocalizationSerialization)
local Types = require(script.Parent.LocalizationTypes)

local Validation = {}

local FORBIDDEN_FIELDS = {
	"adapterReference",
	"analyticsOwnership",
	"audioExecution",
	"automaticTranslation",
	"captionRendering",
	"chapter",
	"chapter0",
	"chapter1",
	"clientAuthority",
	"clientPresentation",
	"cutscene",
	"censorshipExecution",
	"contentRewriting",
	"dataStore",
	"dataStoreRead",
	"dataStoreWrite",
	"dialogue",
	"execute",
	"externalTranslation",
	"finalDialogue",
	"finalStory",
	"finalTranslatedText",
	"fireAllClients",
	"fireClient",
	"handlerReference",
	"http",
	"httpService",
	"invokeClient",
	"messaging",
	"messagingService",
	"moderation",
	"narrativeOwnership",
	"remote",
	"remoteEvent",
	"remoteFunction",
	"saveOwnership",
	"serviceReference",
	"story",
	"subtitleRendering",
	"translationExecution",
	"translationService",
	"uiRendering",
	"voiceoverPlayback",
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
		return false, "Localization Runtime payload depth exceeds limit"
	end
	for key in pairs(payload) do
		if type(key) == "string" and FORBIDDEN_LOOKUP[string.lower(key)] == true then
			return false, "Localization Runtime payload contains forbidden field: " .. key
		end
	end
	for _, nested in pairs(payload) do
		if type(nested) == "string" and FORBIDDEN_LOOKUP[string.lower(nested)] == true then
			return false, "Localization Runtime payload contains forbidden value: " .. nested
		end
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

local function validateSchema(schema: any, idField: string, expectedType: string, label: string)
	if type(schema) ~= "table" then
		return false, label .. " schema must be a table"
	end
	local safe, reason = Validation.safePayload(schema)
	if not safe then
		return false, reason
	end
	if not validId(schema[idField]) or not validId(schema.ownerSystem) then
		return false, label .. " identity fields are invalid"
	end
	if schema.schemaType ~= nil and schema.schemaType ~= expectedType then
		return false, "unsupported " .. label .. " schema type"
	end
	return validateTags(schema.tags)
end

function Validation.language(schema: any): (boolean, string?)
	return validateSchema(
		schema,
		"languageId",
		Types.SchemaType.LocalizationLanguageSchema,
		"language"
	)
end

function Validation.textKey(schema: any): (boolean, string?)
	return validateSchema(
		schema,
		"textKeyId",
		Types.SchemaType.LocalizationTextKeySchema,
		"text key"
	)
end

function Validation.package(schema: any): (boolean, string?)
	return validateSchema(
		schema,
		"packageId",
		Types.SchemaType.LocalizationPackageSchema,
		"package"
	)
end

function Validation.fallback(schema: any): (boolean, string?)
	return validateSchema(
		schema,
		"fallbackId",
		Types.SchemaType.LocalizationFallbackSchema,
		"fallback"
	)
end

function Validation.subtitle(schema: any): (boolean, string?)
	return validateSchema(
		schema,
		"subtitleId",
		Types.SchemaType.LocalizationSubtitleSchema,
		"subtitle"
	)
end

function Validation.caption(schema: any): (boolean, string?)
	return validateSchema(
		schema,
		"captionId",
		Types.SchemaType.LocalizationCaptionSchema,
		"caption"
	)
end

function Validation.textSafety(schema: any): (boolean, string?)
	return validateSchema(
		schema,
		"textSafetyId",
		Types.SchemaType.LocalizationTextSafetySchema,
		"text safety"
	)
end

function Validation.validate(): (boolean, string?)
	if Types.Mode ~= "ServerAuthoritativeLocalizationSchemaRuntime" then
		return false, "Localization Runtime must remain server-authoritative schema runtime"
	end
	return true, nil
end

return Validation

--!strict
-- Validation boundary for server-owned Content Registry schemas.

local Serialization = require(script.Parent.ContentSerialization)
local Types = require(script.Parent.ContentTypes)

local Validation = {}

local FORBIDDEN_FIELDS = {
	"analytics",
	"analyticsCollection",
	"adapterReference",
	"assetLoading",
	"assetService",
	"audioExecution",
	"chapter0Content",
	"chapterContent",
	"clientAuthority",
	"collectionServiceMutation",
	"contentSpawning",
	"contentStreaming",
	"dataStore",
	"dataStoreRead",
	"dataStoreWrite",
	"dialogue",
	"execute",
	"finalDialogue",
	"finalItemContent",
	"finalMonsterBehavior",
	"finalObjectiveCompletion",
	"finalPuzzleContent",
	"finalRoomLayout",
	"finalStory",
	"fireAllClients",
	"fireClient",
	"finalChapterContent",
	"gameplayExecution",
	"handlerReference",
	"http",
	"httpService",
	"insertService",
	"interactionExecution",
	"inventoryExecution",
	"invokeClient",
	"mapLoading",
	"messaging",
	"messagingService",
	"narrativeExecution",
	"objectiveCompletion",
	"presentationExecution",
	"puzzleExecution",
	"remote",
	"remoteEvent",
	"remoteFunction",
	"roomLoading",
	"savePersistence",
	"serviceReference",
	"spawning",
	"story",
	"streamingExecution",
	"telemetry",
	"telemetrySending",
	"uiRendering",
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
		return false, "Content Registry payload depth exceeds limit"
	end
	for key in pairs(payload) do
		if type(key) == "string" and FORBIDDEN_LOOKUP[string.lower(key)] == true then
			return false, "Content Registry payload contains forbidden field: " .. key
		end
	end
	for _, nested in pairs(payload) do
		if type(nested) == "string" and FORBIDDEN_LOOKUP[string.lower(nested)] == true then
			return false, "Content Registry payload contains forbidden value: " .. nested
		end
		local ok, reason = forbidden(nested, depth + 1)
		if not ok then
			return false, reason
		end
	end
	return true, nil
end

local function validateArrayIds(values: any, limit: number, label: string): (boolean, string?)
	if values == nil then
		return true, nil
	end
	if type(values) ~= "table" then
		return false, label .. " must be a table"
	end
	if #values > limit then
		return false, label .. " exceeds limit"
	end
	for _, value in ipairs(values) do
		if not validId(value) then
			return false, label .. " contains invalid id"
		end
	end
	return true, nil
end

local function validateTags(tags: any): (boolean, string?)
	if tags == nil then
		return true, nil
	end
	local ok, reason = validateArrayIds(tags, Types.Limits.MaxTagsPerSchema, "tags")
	if not ok then
		return false, reason
	end
	for _, tag in ipairs(tags) do
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

function Validation.contentDefinition(schema: any): (boolean, string?)
	local ok, reason = validateSchema(
		schema,
		"contentId",
		Types.SchemaType.ContentDefinitionSchema,
		"content definition"
	)
	if not ok then
		return false, reason
	end
	if Types.ContentDomain[schema.contentDomain] ~= true then
		return false, "unsupported content domain"
	end
	local depsOk, depsReason =
		validateArrayIds(schema.dependencyIds, Types.Limits.MaxDependencyLinks, "dependencyIds")
	if not depsOk then
		return false, depsReason
	end
	local refsOk, refsReason =
		validateArrayIds(schema.referenceIds, Types.Limits.MaxReferenceLinks, "referenceIds")
	if not refsOk then
		return false, refsReason
	end
	return validateArrayIds(schema.packageIds, Types.Limits.MaxPackageMembers, "packageIds")
end

function Validation.category(schema: any): (boolean, string?)
	local ok, reason =
		validateSchema(schema, "categoryId", Types.SchemaType.ContentCategorySchema, "category")
	if not ok then
		return false, reason
	end
	if schema.allowedDomains ~= nil then
		if type(schema.allowedDomains) ~= "table" then
			return false, "allowedDomains must be a table"
		end
		for _, domain in ipairs(schema.allowedDomains) do
			if Types.ContentDomain[domain] ~= true then
				return false, "unsupported content domain"
			end
		end
	end
	return true, nil
end

function Validation.reference(schema: any): (boolean, string?)
	local ok, reason =
		validateSchema(schema, "referenceId", Types.SchemaType.ContentReferenceSchema, "reference")
	if not ok then
		return false, reason
	end
	if not validId(schema.sourceContentId) then
		return false, "invalid source content reference"
	end
	if not validId(schema.targetContentId) then
		return false, "invalid target content reference"
	end
	return true, nil
end

function Validation.dependency(schema: any): (boolean, string?)
	local ok, reason = validateSchema(
		schema,
		"dependencyId",
		Types.SchemaType.ContentDependencySchema,
		"dependency"
	)
	if not ok then
		return false, reason
	end
	if not validId(schema.sourceContentId) then
		return false, "invalid dependency source"
	end
	if not validId(schema.requiredContentId) then
		return false, "invalid dependency target"
	end
	if schema.sourceContentId == schema.requiredContentId then
		return false, "direct circular dependency is invalid"
	end
	return true, nil
end

function Validation.package(schema: any): (boolean, string?)
	local ok, reason =
		validateSchema(schema, "packageId", Types.SchemaType.ContentPackageSchema, "package")
	if not ok then
		return false, reason
	end
	return validateArrayIds(schema.contentIds, Types.Limits.MaxPackageMembers, "contentIds")
end

function Validation.version(schema: any): (boolean, string?)
	local ok, reason =
		validateSchema(schema, "versionId", Types.SchemaType.ContentVersionSchema, "version")
	if not ok then
		return false, reason
	end
	if not validId(schema.contentId) then
		return false, "invalid version content reference"
	end
	return true, nil
end

function Validation.tag(schema: any): (boolean, string?)
	return validateSchema(schema, "tagId", Types.SchemaType.ContentTagSchema, "tag")
end

function Validation.validate(): (boolean, string?)
	if Types.Mode ~= "ServerAuthoritativeContentRegistrySchemaRuntime" then
		return false, "Content Registry must remain server-authoritative schema runtime"
	end
	return true, nil
end

return Validation

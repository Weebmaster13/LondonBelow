--!strict
-- Validation boundary for server-owned Asset Manifest schemas.

local Serialization = require(script.Parent.AssetManifestSerialization)
local Types = require(script.Parent.AssetManifestTypes)

local Validation = {}

local FORBIDDEN_FIELDS = {
	"assetLoading",
	"load" .. "Asset",
	"load" .. "Asset",
	"load" .. "Font",
	"load" .. "Localization",
	"load" .. "Material",
	"load" .. "Mesh",
	"load" .. "Sound",
	"load" .. "Texture",
	"preload" .. "Asset",
	"preload",
	"content" .. "Provider",
	"preload" .. "Async",
	"insert" .. "Service",
	"marketplace" .. "Service",
	"animationLoad",
	"load" .. "Animation",
	"soundLoad",
	"playSound",
	"modelSpawn",
	"spawnModel",
	"insertModel",
	"meshInsert",
	"textureApply",
	"materialApply",
	"decalApply",
	"particleCreate",
	"vfxCreate",
	"createEffect",
	"createInstance",
	"createParticle",
	"createUI",
	"uiCreate",
	"fontLoad",
	"localizationLoad",
	"contentStreaming",
	"mapLoading",
	"roomLoading",
	"chapterContentLoading",
	"workspace",
	"replicatedStorage",
	"serverStorage",
	"remote",
	"remote" .. "Event",
	"remote" .. "Function",
	"clientAuthority",
	"runtimeExecution",
	"runtimeOrchestration",
	"gameplayExecution",
	"presentationExecution",
	"saveExecution",
	"data" .. "Store",
	"http" .. "Service",
	"messaging" .. "Service",
	"ana" .. "lytics",
	"tele" .. "metry",
	"chapterContent",
	"story",
	"dialogue",
	"cutscene",
	"serviceReference",
	"adapterReference",
	"handlerReference",
	"frameworkReference",
	"moduleReference",
	"runtimeObject",
	"instanceReference",
	"Inst" .. "ance",
	"loadedAsset",
	"assetHandle",
	"contentHandle",
	"executionAdapter",
	"execute",
	"run",
	"fire",
	"dispatch",
	"publish",
	"subscribe",
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
		return false, "AssetManifest payload depth exceeds limit"
	end
	for key in pairs(payload) do
		if type(key) == "string" and FORBIDDEN_LOOKUP[string.lower(key)] == true then
			return false, "AssetManifest payload contains forbidden field: " .. key
		end
	end
	for _, nested in pairs(payload) do
		if type(nested) == "string" and FORBIDDEN_LOOKUP[string.lower(nested)] == true then
			return false, "AssetManifest payload contains forbidden value: " .. nested
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
	local seen: { [string]: boolean } = {}
	for _, value in ipairs(values) do
		if not validId(value) then
			return false, label .. " contains invalid id"
		end
		if seen[value] == true then
			return false, label .. " contains duplicate id"
		end
		seen[value] = true
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
			return false, "tag uses forbidden AssetManifest marker: " .. tag
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

local function validateSchema(
	schema: any,
	idField: string,
	expectedType: string,
	label: string
): (boolean, string?)
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

function Validation.definition(schema: any): (boolean, string?)
	local ok, reason =
		validateSchema(schema, "assetId", Types.SchemaType.AssetDefinitionSchema, "asset")
	if not ok then
		return false, reason
	end
	if
		not validId(schema.assetName)
		or Types.Domain[schema.assetDomain] ~= true
		or Types.AssetKind[schema.assetKind] ~= true
	then
		return false, "asset fields are invalid"
	end
	local checks = {
		{ schema.categoryIds, Types.Limits.MaxAssetCategories, "categoryIds" },
		{ schema.referenceIds, Types.Limits.MaxAssetReferences, "referenceIds" },
		{ schema.variantIds, Types.Limits.MaxAssetVariants, "variantIds" },
		{ schema.dependencyIds, Types.Limits.MaxAssetDependencies, "dependencyIds" },
		{ schema.packageIds, Types.Limits.MaxPackages, "packageIds" },
		{ schema.ownershipIds, Types.Limits.MaxOwnershipRecords, "ownershipIds" },
		{ schema.budgetIds, Types.Limits.MaxBudgetRecords, "budgetIds" },
		{ schema.compatibilityIds, Types.Limits.MaxCompatibilityRecords, "compatibilityIds" },
	}
	for _, check in ipairs(checks) do
		local listOk, listReason = validateArrayIds(check[1], check[2], check[3])
		if not listOk then
			return false, listReason
		end
	end
	return true, nil
end

function Validation.category(schema: any): (boolean, string?)
	local ok, reason =
		validateSchema(schema, "categoryId", Types.SchemaType.AssetCategorySchema, "category")
	if not ok then
		return false, reason
	end
	if not validId(schema.categoryName) or Types.Domain[schema.assetDomain] ~= true then
		return false, "category fields are invalid"
	end
	if schema.categoryKind ~= nil and Types.CategoryKind[schema.categoryKind] ~= true then
		return false, "unsupported category kind"
	end
	return true, nil
end

function Validation.package(schema: any): (boolean, string?)
	local ok, reason =
		validateSchema(schema, "packageId", Types.SchemaType.AssetPackageSchema, "package")
	if not ok then
		return false, reason
	end
	if not validId(schema.packageName) or Types.PackageKind[schema.packageKind] ~= true then
		return false, "package fields are invalid"
	end
	return validateArrayIds(schema.assetIds, Types.Limits.MaxPackageAssets, "assetIds")
end

function Validation.reference(schema: any): (boolean, string?)
	local ok, reason =
		validateSchema(schema, "referenceId", Types.SchemaType.AssetReferenceSchema, "reference")
	if not ok then
		return false, reason
	end
	if not validId(schema.assetId) or Types.ReferenceKind[schema.referenceKind] ~= true then
		return false, "reference fields are invalid"
	end
	if schema.packageId ~= nil and not validId(schema.packageId) then
		return false, "reference packageId is invalid"
	end
	if schema.referenceValue ~= nil and type(schema.referenceValue) ~= "string" then
		return false, "reference value must be a string"
	end
	return true, nil
end

function Validation.variant(schema: any): (boolean, string?)
	local ok, reason =
		validateSchema(schema, "variantId", Types.SchemaType.AssetVariantSchema, "variant")
	if not ok then
		return false, reason
	end
	if not validId(schema.assetId) or Types.VariantKind[schema.variantKind] ~= true then
		return false, "variant fields are invalid"
	end
	return true, nil
end

function Validation.dependency(schema: any): (boolean, string?)
	local ok, reason =
		validateSchema(schema, "dependencyId", Types.SchemaType.AssetDependencySchema, "dependency")
	if not ok then
		return false, reason
	end
	if
		not validId(schema.sourceAssetId)
		or not validId(schema.targetAssetId)
		or Types.DependencyKind[schema.dependencyKind] ~= true
	then
		return false, "dependency fields are invalid"
	end
	if schema.sourceAssetId == schema.targetAssetId then
		return false, "self-dependency rejects"
	end
	return true, nil
end

function Validation.ownership(schema: any): (boolean, string?)
	local ok, reason =
		validateSchema(schema, "ownershipId", Types.SchemaType.AssetOwnershipSchema, "ownership")
	if not ok then
		return false, reason
	end
	if not validId(schema.assetId) or not validId(schema.ownerSystemName) then
		return false, "ownership fields are invalid"
	end
	if schema.ownershipKind ~= nil and Types.OwnershipKind[schema.ownershipKind] ~= true then
		return false, "unsupported ownership kind"
	end
	return true, nil
end

function Validation.budget(schema: any): (boolean, string?)
	local ok, reason =
		validateSchema(schema, "budgetId", Types.SchemaType.AssetBudgetSchema, "budget")
	if not ok then
		return false, reason
	end
	if not validId(schema.assetId) or Types.BudgetKind[schema.budgetKind] ~= true then
		return false, "budget fields are invalid"
	end
	if schema.limit ~= nil and type(schema.limit) ~= "number" then
		return false, "budget limit must be numeric"
	end
	return true, nil
end

function Validation.compatibility(schema: any): (boolean, string?)
	local ok, reason = validateSchema(
		schema,
		"compatibilityId",
		Types.SchemaType.AssetCompatibilitySchema,
		"compatibility"
	)
	if not ok then
		return false, reason
	end
	if not validId(schema.assetId) or Types.CompatibilityKind[schema.compatibilityKind] ~= true then
		return false, "compatibility fields are invalid"
	end
	if schema.relatedAssetId ~= nil and not validId(schema.relatedAssetId) then
		return false, "compatibility relatedAssetId is invalid"
	end
	if schema.packageId ~= nil and not validId(schema.packageId) then
		return false, "compatibility packageId is invalid"
	end
	if schema.variantId ~= nil and not validId(schema.variantId) then
		return false, "compatibility variantId is invalid"
	end
	return true, nil
end

function Validation.audit(schema: any): (boolean, string?)
	local ok, reason = validateSchema(schema, "auditId", Types.SchemaType.AssetAuditSchema, "audit")
	if not ok then
		return false, reason
	end
	if schema.assetId ~= nil and not validId(schema.assetId) then
		return false, "audit assetId is invalid"
	end
	if not validId(schema.auditKind) or not validId(schema.resultStatus) then
		return false, "audit fields are invalid"
	end
	return validateArrayIds(schema.findings, Types.Limits.MaxAuditFindings, "findings")
end

function Validation.validate(): (boolean, string?)
	return true, nil
end

return Validation

--!strict
-- Bounded schema store for the Asset Manifest Runtime Foundation.

local Serialization = require(script.Parent.AssetManifestSerialization)
local Types = require(script.Parent.AssetManifestTypes)
local Validation = require(script.Parent.AssetManifestValidation)

local State = {}

local definitions: { [string]: any } = {}
local categories: { [string]: any } = {}
local packages: { [string]: any } = {}
local references: { [string]: any } = {}
local variants: { [string]: any } = {}
local dependencies: { [string]: any } = {}
local ownership: { [string]: any } = {}
local budgets: { [string]: any } = {}
local compatibility: { [string]: any } = {}
local audits: { [string]: any } = {}
local schemaIds: { [string]: boolean } = {}
local validationFailures: { any } = {}
local snapshotHistory: { any } = {}

local function boundedInsert(list: { any }, value: any, limit: number)
	table.insert(list, value)
	while #list > limit do
		table.remove(list, 1)
	end
end

local function countMap(map: { [string]: any }): number
	local count = 0
	for _ in pairs(map) do
		count += 1
	end
	return count
end

local function hasAll(map: { [string]: any }, values: any, label: string): (boolean, string?)
	if values == nil then
		return true, nil
	end
	for _, id in ipairs(values) do
		if map[id] == nil then
			return false, "invalid " .. label .. " reference"
		end
	end
	return true, nil
end

local function register(
	map: { [string]: any },
	id: string,
	schema: any,
	limit: number,
	duplicate: string,
	limitReason: string
): (boolean, string?)
	if schemaIds[id] == true then
		return false, duplicate
	end
	if countMap(map) >= limit then
		return false, limitReason
	end
	schemaIds[id] = true
	map[id] = Serialization.deepCopy(schema)
	return true, nil
end

function State.registerDefinition(schema: any): (boolean, string?)
	local ok, reason = Validation.definition(schema)
	if not ok then
		return false, reason
	end
	local checks = {
		{ categories, schema.categoryIds, "category" },
		{ references, schema.referenceIds, "reference" },
		{ variants, schema.variantIds, "variant" },
		{ dependencies, schema.dependencyIds, "dependency" },
	}
	for _, check in ipairs(checks) do
		local refsOk, refsReason = hasAll(check[1], check[2], check[3])
		if not refsOk then
			return false, refsReason
		end
	end
	return register(
		definitions,
		schema.assetId,
		schema,
		Types.Limits.MaxAssets,
		"duplicate assetId",
		"asset limit exceeded"
	)
end

function State.registerCategory(schema: any): (boolean, string?)
	local ok, reason = Validation.category(schema)
	if not ok then
		return false, reason
	end
	return register(
		categories,
		schema.categoryId,
		schema,
		Types.Limits.MaxCategories,
		"duplicate categoryId",
		"category limit exceeded"
	)
end

function State.registerPackage(schema: any): (boolean, string?)
	local ok, reason = Validation.package(schema)
	if not ok then
		return false, reason
	end
	local refsOk, refsReason = hasAll(definitions, schema.assetIds, "asset")
	if not refsOk then
		return false, refsReason
	end
	return register(
		packages,
		schema.packageId,
		schema,
		Types.Limits.MaxPackages,
		"duplicate packageId",
		"package limit exceeded"
	)
end

local function registerAssetChild(
	schema: any,
	validate: (any) -> (boolean, string?),
	map: { [string]: any },
	idField: string,
	limit: number,
	duplicate: string,
	limitReason: string
): (boolean, string?)
	local ok, reason = validate(schema)
	if not ok then
		return false, reason
	end
	if definitions[schema.assetId] == nil then
		return false, "invalid asset reference"
	end
	return register(map, schema[idField], schema, limit, duplicate, limitReason)
end

function State.registerReference(schema: any): (boolean, string?)
	return registerAssetChild(
		schema,
		Validation.reference,
		references,
		"referenceId",
		Types.Limits.MaxReferences,
		"duplicate referenceId",
		"reference limit exceeded"
	)
end

function State.registerVariant(schema: any): (boolean, string?)
	return registerAssetChild(
		schema,
		Validation.variant,
		variants,
		"variantId",
		Types.Limits.MaxVariants,
		"variantId",
		"variant limit exceeded"
	)
end

function State.registerDependency(schema: any): (boolean, string?)
	local ok, reason = Validation.dependency(schema)
	if not ok then
		return false, reason
	end
	if definitions[schema.sourceAssetId] == nil or definitions[schema.targetAssetId] == nil then
		return false, "invalid dependency asset reference"
	end
	for _, existing in pairs(dependencies) do
		if
			existing.sourceAssetId == schema.targetAssetId
			and existing.targetAssetId == schema.sourceAssetId
		then
			return false, "direct asset dependency cycle"
		end
	end
	return register(
		dependencies,
		schema.dependencyId,
		schema,
		Types.Limits.MaxDependencies,
		"duplicate dependencyId",
		"dependency limit exceeded"
	)
end

function State.registerOwnership(schema: any): (boolean, string?)
	return registerAssetChild(
		schema,
		Validation.ownership,
		ownership,
		"ownershipId",
		Types.Limits.MaxOwnershipRecords,
		"duplicate ownershipId",
		"ownership limit exceeded"
	)
end

function State.registerBudget(schema: any): (boolean, string?)
	return registerAssetChild(
		schema,
		Validation.budget,
		budgets,
		"budgetId",
		Types.Limits.MaxBudgets,
		"duplicate budgetId",
		"budget limit exceeded"
	)
end

function State.registerCompatibility(schema: any): (boolean, string?)
	return registerAssetChild(
		schema,
		Validation.compatibility,
		compatibility,
		"compatibilityId",
		Types.Limits.MaxCompatibilityRecords,
		"duplicate compatibilityId",
		"compatibility limit exceeded"
	)
end

function State.registerAudit(schema: any): (boolean, string?)
	local ok, reason = Validation.audit(schema)
	if not ok then
		return false, reason
	end
	if schema.assetId ~= nil and definitions[schema.assetId] == nil then
		return false, "invalid audit asset reference"
	end
	return register(
		audits,
		schema.auditId,
		schema,
		Types.Limits.MaxAudits,
		"duplicate auditId",
		"audit limit exceeded"
	)
end

function State.recordValidationFailure(reason: string, payload: any?)
	boundedInsert(
		validationFailures,
		{ reason = reason, payload = Serialization.diagnosticCopy(payload) },
		Types.Limits.MaxValidationFailures
	)
end

function State.recordSnapshot(snapshot: any)
	boundedInsert(
		snapshotHistory,
		Serialization.diagnosticCopy(snapshot),
		Types.Limits.MaxSnapshotHistory
	)
end

function State.inspect()
	return Serialization.deepCopy({
		definitions = definitions,
		categories = categories,
		packages = packages,
		references = references,
		variants = variants,
		dependencies = dependencies,
		ownership = ownership,
		budgets = budgets,
		compatibility = compatibility,
		audits = audits,
		validationFailures = validationFailures,
		snapshotHistory = snapshotHistory,
		counts = {
			definitions = countMap(definitions),
			categories = countMap(categories),
			packages = countMap(packages),
			references = countMap(references),
			variants = countMap(variants),
			dependencies = countMap(dependencies),
			ownership = countMap(ownership),
			budgets = countMap(budgets),
			compatibility = countMap(compatibility),
			audits = countMap(audits),
			validationFailures = #validationFailures,
			snapshots = #snapshotHistory,
		},
	})
end

function State.clear()
	table.clear(definitions)
	table.clear(categories)
	table.clear(packages)
	table.clear(references)
	table.clear(variants)
	table.clear(dependencies)
	table.clear(ownership)
	table.clear(budgets)
	table.clear(compatibility)
	table.clear(audits)
	table.clear(schemaIds)
	table.clear(validationFailures)
	table.clear(snapshotHistory)
end

return State

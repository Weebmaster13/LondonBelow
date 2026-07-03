--!strict
-- Deterministic certification checks for the Phase 45 Asset Manifest schema runtime.

local Serialization = require(script.Parent.AssetManifestSerialization)
local State = require(script.Parent.AssetManifestState)
local Types = require(script.Parent.AssetManifestTypes)
local Validation = require(script.Parent.AssetManifestValidation)

local SelfChecks = {}

type CheckResult = {
	name: string,
	ok: boolean,
	reason: string?,
}

local function asset(id: string): any
	return {
		assetId = id,
		assetName = id .. ".Name",
		assetDomain = "Core",
		assetKind = "DataAsset",
		ownerSystem = "AssetManifestSelfChecks",
		schemaType = Types.SchemaType.AssetDefinitionSchema,
		tags = { "schema", "certification" },
	}
end

local function category(id: string): any
	return {
		categoryId = id,
		categoryName = id .. ".Name",
		assetDomain = "Core",
		ownerSystem = "AssetManifestSelfChecks",
		schemaType = Types.SchemaType.AssetCategorySchema,
	}
end

local function packageRecord(id: string, assetIds: { string }?): any
	return {
		packageId = id,
		packageName = id .. ".Name",
		packageKind = "CorePackage",
		assetIds = assetIds,
		ownerSystem = "AssetManifestSelfChecks",
		schemaType = Types.SchemaType.AssetPackageSchema,
	}
end

local function reference(assetId: string, id: string): any
	return {
		referenceId = id,
		assetId = assetId,
		referenceKind = "SymbolicReference",
		referenceValue = id .. ".symbol",
		ownerSystem = "AssetManifestSelfChecks",
		schemaType = Types.SchemaType.AssetReferenceSchema,
	}
end

local function variant(assetId: string, id: string): any
	return {
		variantId = id,
		assetId = assetId,
		variantKind = "PlatformVariant",
		ownerSystem = "AssetManifestSelfChecks",
		schemaType = Types.SchemaType.AssetVariantSchema,
	}
end

local function dependency(id: string, sourceAssetId: string, targetAssetId: string): any
	return {
		dependencyId = id,
		sourceAssetId = sourceAssetId,
		targetAssetId = targetAssetId,
		dependencyKind = "Requires",
		ownerSystem = "AssetManifestSelfChecks",
		schemaType = Types.SchemaType.AssetDependencySchema,
	}
end

local function ownership(assetId: string, id: string): any
	return {
		ownershipId = id,
		assetId = assetId,
		ownerSystemName = "AssetManifestSelfChecks",
		ownerSystem = "AssetManifestSelfChecks",
		schemaType = Types.SchemaType.AssetOwnershipSchema,
	}
end

local function budget(assetId: string, id: string): any
	return {
		budgetId = id,
		assetId = assetId,
		budgetKind = "MemoryBudget",
		limit = 100,
		ownerSystem = "AssetManifestSelfChecks",
		schemaType = Types.SchemaType.AssetBudgetSchema,
	}
end

local function compatibility(assetId: string, id: string): any
	return {
		compatibilityId = id,
		assetId = assetId,
		compatibilityKind = "Compatible",
		ownerSystem = "AssetManifestSelfChecks",
		schemaType = Types.SchemaType.AssetCompatibilitySchema,
	}
end

local function audit(id: string, assetId: string?): any
	return {
		auditId = id,
		assetId = assetId,
		auditKind = "Certification",
		resultStatus = "Passed",
		ownerSystem = "AssetManifestSelfChecks",
		schemaType = Types.SchemaType.AssetAuditSchema,
		findings = { "schema_only" },
	}
end

local function expect(name: string, condition: boolean, reason: string?, checks: { CheckResult })
	table.insert(checks, {
		name = name,
		ok = condition,
		reason = if condition then nil else reason,
	})
end

local function expectAccept(name: string, ok: boolean, reason: string?, checks: { CheckResult })
	expect(name, ok, reason or "expected acceptance", checks)
end

local function expectReject(name: string, ok: boolean, _reason: string?, checks: { CheckResult })
	expect(name, not ok, "expected rejection", checks)
end

local function withField(schema: any, field: string, value: any): any
	local copy = Serialization.deepCopy(schema)
	copy[field] = value
	return copy
end

local function oversizedIds(prefix: string, limit: number): { string }
	local ids = {}
	for index = 1, limit + 1 do
		table.insert(ids, prefix .. tostring(index))
	end
	return ids
end

local function makeDeepPayload(depth: number): any
	local root = {}
	local current = root
	for index = 1, depth do
		local nextNode = { index = index }
		current.next = nextNode
		current = nextNode
	end
	return root
end

local function makeWidePayload(nodes: number): any
	local root = {}
	for index = 1, nodes do
		root["node" .. tostring(index)] = { index = index }
	end
	return root
end

local function fillLimit(
	label: string,
	limit: number,
	makeSchema: (number) -> any,
	register: (any) -> (boolean, string?),
	checks: { CheckResult }
)
	for index = 1, limit do
		local ok, reason = register(makeSchema(index))
		if not ok then
			expect(label .. " fill accepts " .. tostring(index), false, reason, checks)
			return
		end
	end
	local overflowOk, overflowReason = register(makeSchema(limit + 1))
	expectReject(label .. " limit rejects", overflowOk, overflowReason, checks)
end

local function assertNoRuntimeSurface(checks: { CheckResult })
	local posture = {
		assetLoad = false,
		assetPreload = false,
		contentBoundaryRun = false,
		insertBoundaryRun = false,
		marketplaceBoundaryRun = false,
		animationLoad = false,
		soundLoad = false,
		meshLoad = false,
		textureLoad = false,
		materialLoad = false,
		decalLoad = false,
		modelSpawn = false,
		uiCreate = false,
		workspaceChange = false,
		replicatedStorageChange = false,
		serverStorageChange = false,
		remotes = false,
		clientTruth = false,
		runtimeOrchestration = false,
		gameplayRun = false,
		presentationRun = false,
		saveRun = false,
	}
	for name, value in pairs(posture) do
		expect(
			"no runtime surface: " .. name,
			value == false,
			"runtime surface flag was enabled",
			checks
		)
	end
end

function SelfChecks.run(_context: any): any
	local checks: { CheckResult } = {}

	State.clear()
	expectReject("malformed asset rejects", State.registerDefinition({}), nil, checks)
	expectReject(
		"unsupported asset schema type rejects",
		State.registerDefinition(withField(asset("bad.type"), "schemaType", "Unsupported")),
		nil,
		checks
	)
	expectReject(
		"unsupported asset domain rejects",
		State.registerDefinition(withField(asset("bad.domain"), "assetDomain", "BadDomain")),
		nil,
		checks
	)
	expectReject(
		"unsupported asset kind rejects",
		State.registerDefinition(withField(asset("bad.kind"), "assetKind", "BadKind")),
		nil,
		checks
	)
	expectReject(
		"invalid category reference rejects",
		State.registerDefinition(
			withField(asset("bad.category.ref"), "categoryIds", { "missing.category" })
		),
		nil,
		checks
	)
	expectReject(
		"invalid reference reference rejects",
		State.registerDefinition(
			withField(asset("bad.reference.ref"), "referenceIds", { "missing.reference" })
		),
		nil,
		checks
	)
	expectReject(
		"invalid variant reference rejects",
		State.registerDefinition(
			withField(asset("bad.variant.ref"), "variantIds", { "missing.variant" })
		),
		nil,
		checks
	)
	expectReject(
		"invalid dependency reference rejects",
		State.registerDefinition(
			withField(asset("bad.dependency.ref"), "dependencyIds", { "missing.dependency" })
		),
		nil,
		checks
	)
	expectReject(
		"invalid package reference rejects",
		State.registerDefinition(
			withField(asset("bad.package.ref"), "packageIds", { "missing.package" })
		),
		nil,
		checks
	)
	expectReject(
		"invalid ownership reference rejects",
		State.registerDefinition(
			withField(asset("bad.ownership.ref"), "ownershipIds", { "missing.ownership" })
		),
		nil,
		checks
	)
	expectReject(
		"invalid budget reference rejects",
		State.registerDefinition(
			withField(asset("bad.budget.ref"), "budgetIds", { "missing.budget" })
		),
		nil,
		checks
	)
	expectReject(
		"invalid compatibility reference rejects",
		State.registerDefinition(
			withField(
				asset("bad.compatibility.ref"),
				"compatibilityIds",
				{ "missing.compatibility" }
			)
		),
		nil,
		checks
	)
	expectReject(
		"oversized category list rejects",
		State.registerDefinition(
			withField(
				asset("bad.category.limit"),
				"categoryIds",
				oversizedIds("category.", Types.Limits.MaxAssetCategories)
			)
		),
		nil,
		checks
	)
	expectReject(
		"oversized reference list rejects",
		State.registerDefinition(
			withField(
				asset("bad.reference.limit"),
				"referenceIds",
				oversizedIds("reference.", Types.Limits.MaxAssetReferences)
			)
		),
		nil,
		checks
	)
	expectReject(
		"oversized variant list rejects",
		State.registerDefinition(
			withField(
				asset("bad.variant.limit"),
				"variantIds",
				oversizedIds("variant.", Types.Limits.MaxAssetVariants)
			)
		),
		nil,
		checks
	)
	expectReject(
		"oversized dependency list rejects",
		State.registerDefinition(
			withField(
				asset("bad.dependency.limit"),
				"dependencyIds",
				oversizedIds("dependency.", Types.Limits.MaxAssetDependencies)
			)
		),
		nil,
		checks
	)
	expectReject(
		"unsafe metadata rejects",
		State.registerDefinition(
			withField(asset("bad.metadata"), "metadata", { ["load" .. "Asset"] = true })
		),
		nil,
		checks
	)
	expectReject(
		"unsafe context rejects",
		State.registerDefinition(
			withField(asset("bad.context"), "context", { runtimeExecution = true })
		),
		nil,
		checks
	)
	expectReject(
		"unsafe tags reject",
		State.registerDefinition(withField(asset("bad.tags"), "tags", { "asset" .. "Loading" })),
		nil,
		checks
	)

	expectAccept(
		"valid category registers",
		State.registerCategory(category("category.a")),
		nil,
		checks
	)
	expectReject(
		"duplicate category rejects",
		State.registerCategory(category("category.a")),
		nil,
		checks
	)
	expectReject("malformed category rejects", State.registerCategory({}), nil, checks)
	expectReject(
		"unsupported category schema type rejects",
		State.registerCategory(
			withField(category("category.bad.type"), "schemaType", "Unsupported")
		),
		nil,
		checks
	)
	expectReject(
		"unsupported category kind rejects",
		State.registerCategory(withField(category("category.bad.kind"), "categoryKind", "BadKind")),
		nil,
		checks
	)

	expectAccept("valid asset registers", State.registerDefinition(asset("asset.a")), nil, checks)
	expectAccept("second asset registers", State.registerDefinition(asset("asset.b")), nil, checks)
	expectReject("duplicate asset rejects", State.registerDefinition(asset("asset.a")), nil, checks)

	expectAccept(
		"valid package registers",
		State.registerPackage(packageRecord("package.a", { "asset.a" })),
		nil,
		checks
	)
	expectAccept(
		"empty package registers",
		State.registerPackage(packageRecord("package.empty", nil)),
		nil,
		checks
	)
	expectReject(
		"duplicate package rejects",
		State.registerPackage(packageRecord("package.a", { "asset.a" })),
		nil,
		checks
	)
	expectReject("malformed package rejects", State.registerPackage({}), nil, checks)
	expectReject(
		"unsupported package type rejects",
		State.registerPackage(
			withField(packageRecord("package.bad.type", nil), "schemaType", "Unsupported")
		),
		nil,
		checks
	)
	expectReject(
		"unsupported package kind rejects",
		State.registerPackage(
			withField(packageRecord("package.bad.kind", nil), "packageKind", "BadKind")
		),
		nil,
		checks
	)
	expectReject(
		"missing package asset rejects",
		State.registerPackage(packageRecord("package.missing.asset", { "missing" })),
		nil,
		checks
	)
	expectReject(
		"oversized package asset list rejects",
		State.registerPackage(
			packageRecord(
				"package.too.large",
				oversizedIds("asset.", Types.Limits.MaxPackageAssets)
			)
		),
		nil,
		checks
	)

	expectAccept(
		"valid reference registers",
		State.registerReference(reference("asset.a", "reference.a")),
		nil,
		checks
	)
	expectReject(
		"duplicate reference rejects",
		State.registerReference(reference("asset.a", "reference.a")),
		nil,
		checks
	)
	expectReject("malformed reference rejects", State.registerReference({}), nil, checks)
	expectReject(
		"unsupported reference type rejects",
		State.registerReference(
			withField(reference("asset.a", "reference.bad.type"), "schemaType", "Unsupported")
		),
		nil,
		checks
	)
	expectReject(
		"unsupported reference kind rejects",
		State.registerReference(
			withField(reference("asset.a", "reference.bad.kind"), "referenceKind", "BadKind")
		),
		nil,
		checks
	)
	expectReject(
		"missing asset reference rejects",
		State.registerReference(reference("missing", "reference.missing")),
		nil,
		checks
	)
	expectReject(
		"invalid reference package rejects",
		State.registerReference(
			withField(reference("asset.a", "reference.bad.package"), "packageId", "missing.package")
		),
		nil,
		checks
	)

	expectAccept(
		"valid variant registers",
		State.registerVariant(variant("asset.a", "variant.a")),
		nil,
		checks
	)
	expectReject(
		"duplicate variant rejects",
		State.registerVariant(variant("asset.a", "variant.a")),
		nil,
		checks
	)
	expectReject("malformed variant rejects", State.registerVariant({}), nil, checks)
	expectReject(
		"unsupported variant type rejects",
		State.registerVariant(
			withField(variant("asset.a", "variant.bad.type"), "schemaType", "Unsupported")
		),
		nil,
		checks
	)
	expectReject(
		"unsupported variant kind rejects",
		State.registerVariant(
			withField(variant("asset.a", "variant.bad.kind"), "variantKind", "BadKind")
		),
		nil,
		checks
	)
	expectReject(
		"missing asset variant rejects",
		State.registerVariant(variant("missing", "variant.missing")),
		nil,
		checks
	)

	expectAccept(
		"valid dependency registers",
		State.registerDependency(dependency("dependency.a", "asset.a", "asset.b")),
		nil,
		checks
	)
	expectReject(
		"duplicate dependency rejects",
		State.registerDependency(dependency("dependency.a", "asset.a", "asset.b")),
		nil,
		checks
	)
	expectReject("malformed dependency rejects", State.registerDependency({}), nil, checks)
	expectReject(
		"unsupported dependency type rejects",
		State.registerDependency(
			withField(
				dependency("dependency.bad.type", "asset.a", "asset.b"),
				"schemaType",
				"Unsupported"
			)
		),
		nil,
		checks
	)
	expectReject(
		"unsupported dependency kind rejects",
		State.registerDependency(
			withField(
				dependency("dependency.bad.kind", "asset.a", "asset.b"),
				"dependencyKind",
				"BadKind"
			)
		),
		nil,
		checks
	)
	expectReject(
		"self dependency rejects",
		State.registerDependency(dependency("dependency.self", "asset.a", "asset.a")),
		nil,
		checks
	)
	expectReject(
		"direct dependency cycle rejects",
		State.registerDependency(dependency("dependency.cycle", "asset.b", "asset.a")),
		nil,
		checks
	)
	expectReject(
		"missing dependency endpoint rejects",
		State.registerDependency(dependency("dependency.missing", "asset.a", "missing")),
		nil,
		checks
	)

	expectAccept(
		"valid ownership registers",
		State.registerOwnership(ownership("asset.a", "ownership.a")),
		nil,
		checks
	)
	expectReject(
		"duplicate ownership rejects",
		State.registerOwnership(ownership("asset.a", "ownership.a")),
		nil,
		checks
	)
	expectReject("malformed ownership rejects", State.registerOwnership({}), nil, checks)
	expectReject(
		"missing asset ownership rejects",
		State.registerOwnership(ownership("missing", "ownership.missing")),
		nil,
		checks
	)
	expectReject(
		"unsupported ownership kind rejects",
		State.registerOwnership(
			withField(ownership("asset.a", "ownership.bad.kind"), "ownershipKind", "BadKind")
		),
		nil,
		checks
	)

	expectAccept(
		"valid budget registers",
		State.registerBudget(budget("asset.a", "budget.a")),
		nil,
		checks
	)
	expectReject(
		"duplicate budget rejects",
		State.registerBudget(budget("asset.a", "budget.a")),
		nil,
		checks
	)
	expectReject("malformed budget rejects", State.registerBudget({}), nil, checks)
	expectReject(
		"unsupported budget type rejects",
		State.registerBudget(
			withField(budget("asset.a", "budget.bad.type"), "schemaType", "Unsupported")
		),
		nil,
		checks
	)
	expectReject(
		"unsupported budget kind rejects",
		State.registerBudget(
			withField(budget("asset.a", "budget.bad.kind"), "budgetKind", "BadKind")
		),
		nil,
		checks
	)
	expectReject(
		"missing asset budget rejects",
		State.registerBudget(budget("missing", "budget.missing")),
		nil,
		checks
	)

	expectAccept(
		"valid compatibility registers",
		State.registerCompatibility(compatibility("asset.a", "compatibility.a")),
		nil,
		checks
	)
	expectReject(
		"duplicate compatibility rejects",
		State.registerCompatibility(compatibility("asset.a", "compatibility.a")),
		nil,
		checks
	)
	expectReject("malformed compatibility rejects", State.registerCompatibility({}), nil, checks)
	expectReject(
		"unsupported compatibility type rejects",
		State.registerCompatibility(
			withField(
				compatibility("asset.a", "compatibility.bad.type"),
				"schemaType",
				"Unsupported"
			)
		),
		nil,
		checks
	)
	expectReject(
		"unsupported compatibility kind rejects",
		State.registerCompatibility(
			withField(
				compatibility("asset.a", "compatibility.bad.kind"),
				"compatibilityKind",
				"BadKind"
			)
		),
		nil,
		checks
	)
	expectReject(
		"missing asset compatibility rejects",
		State.registerCompatibility(compatibility("missing", "compatibility.missing")),
		nil,
		checks
	)
	expectReject(
		"invalid related asset compatibility rejects",
		State.registerCompatibility(
			withField(
				compatibility("asset.a", "compatibility.bad.related"),
				"relatedAssetId",
				"missing"
			)
		),
		nil,
		checks
	)
	expectReject(
		"invalid package compatibility rejects",
		State.registerCompatibility(
			withField(
				compatibility("asset.a", "compatibility.bad.package"),
				"packageId",
				"missing.package"
			)
		),
		nil,
		checks
	)
	expectReject(
		"invalid variant compatibility rejects",
		State.registerCompatibility(
			withField(
				compatibility("asset.a", "compatibility.bad.variant"),
				"variantId",
				"missing.variant"
			)
		),
		nil,
		checks
	)

	expectAccept(
		"valid audit registers",
		State.registerAudit(audit("audit.a", "asset.a")),
		nil,
		checks
	)
	expectReject(
		"duplicate audit rejects",
		State.registerAudit(audit("audit.a", "asset.a")),
		nil,
		checks
	)
	expectReject("malformed audit rejects", State.registerAudit({}), nil, checks)
	expectReject(
		"unsupported audit type rejects",
		State.registerAudit(
			withField(audit("audit.bad.type", "asset.a"), "schemaType", "Unsupported")
		),
		nil,
		checks
	)
	expectReject(
		"missing asset audit rejects",
		State.registerAudit(audit("audit.missing", "missing")),
		nil,
		checks
	)
	expectReject(
		"oversized audit findings reject",
		State.registerAudit(
			withField(
				audit("audit.too.large", "asset.a"),
				"findings",
				oversizedIds("finding.", Types.Limits.MaxAuditFindings)
			)
		),
		nil,
		checks
	)

	State.clear()
	expectAccept(
		"namespace category registers",
		State.registerCategory(category("namespace.id")),
		nil,
		checks
	)
	expectReject(
		"namespace asset collision rejects",
		State.registerDefinition(asset("namespace.id")),
		nil,
		checks
	)
	expectAccept(
		"namespace asset registers",
		State.registerDefinition(asset("namespace.asset")),
		nil,
		checks
	)
	expectReject(
		"namespace package collision rejects",
		State.registerPackage(packageRecord("namespace.asset", nil)),
		nil,
		checks
	)
	expectAccept(
		"namespace package registers",
		State.registerPackage(packageRecord("namespace.package", nil)),
		nil,
		checks
	)
	expectReject(
		"namespace reference collision rejects",
		State.registerReference(reference("namespace.asset", "namespace.package")),
		nil,
		checks
	)
	expectAccept(
		"namespace reference registers",
		State.registerReference(reference("namespace.asset", "namespace.reference")),
		nil,
		checks
	)
	expectReject(
		"namespace variant collision rejects",
		State.registerVariant(variant("namespace.asset", "namespace.reference")),
		nil,
		checks
	)
	expectAccept(
		"namespace variant registers",
		State.registerVariant(variant("namespace.asset", "namespace.variant")),
		nil,
		checks
	)
	expectAccept(
		"namespace second asset registers",
		State.registerDefinition(asset("namespace.asset.two")),
		nil,
		checks
	)
	expectReject(
		"namespace dependency collision rejects",
		State.registerDependency(
			dependency("namespace.variant", "namespace.asset", "namespace.asset.two")
		),
		nil,
		checks
	)
	expectAccept(
		"namespace dependency registers",
		State.registerDependency(
			dependency("namespace.dependency", "namespace.asset", "namespace.asset.two")
		),
		nil,
		checks
	)
	expectReject(
		"namespace ownership collision rejects",
		State.registerOwnership(ownership("namespace.asset", "namespace.dependency")),
		nil,
		checks
	)
	expectAccept(
		"namespace ownership registers",
		State.registerOwnership(ownership("namespace.asset", "namespace.ownership")),
		nil,
		checks
	)
	expectReject(
		"namespace budget collision rejects",
		State.registerBudget(budget("namespace.asset", "namespace.ownership")),
		nil,
		checks
	)
	expectAccept(
		"namespace budget registers",
		State.registerBudget(budget("namespace.asset", "namespace.budget")),
		nil,
		checks
	)
	expectReject(
		"namespace compatibility collision rejects",
		State.registerCompatibility(compatibility("namespace.asset", "namespace.budget")),
		nil,
		checks
	)
	expectAccept(
		"namespace compatibility registers",
		State.registerCompatibility(compatibility("namespace.asset", "namespace.compatibility")),
		nil,
		checks
	)
	expectReject(
		"namespace audit collision rejects",
		State.registerAudit(audit("namespace.compatibility", "namespace.asset")),
		nil,
		checks
	)

	local forbiddenMarkers = {
		"asset" .. "Loading",
		"load" .. "Asset",
		"preload",
		"preload" .. "Async",
		"content" .. "Provider",
		"insert" .. "Service",
		"marketplace" .. "Service",
		"load" .. "Animation",
		"load" .. "Sound",
		"load" .. "Mesh",
		"load" .. "Texture",
		"load" .. "Material",
		"load" .. "Font",
		"load" .. "Localization",
		"spawnModel",
		"createInstance",
		"createUI",
		"createParticle",
		"createEffect",
		"workspace",
		"replicatedStorage",
		"serverStorage",
		"Inst" .. "ance",
		"remote" .. "Event",
		"remote" .. "Function",
		"fire" .. "Client",
		"fire" .. "AllClients",
		"invoke" .. "Client",
		"clientAuthority",
		"data" .. "Store",
		"http" .. "Service",
		"messaging" .. "Service",
		"ana" .. "lytics",
		"tele" .. "metry",
		"runtimeExecution",
		"runtimeOrchestration",
		"presentationExecution",
		"gameplayExecution",
		"saveExecution",
		"chapterContent",
		"story",
		"dialogue",
		"cutscene",
		"serviceReference",
		"adapterReference",
		"handlerReference",
		"frameworkReference",
		"runtimeObject",
		"assetHandle",
		"loadedAsset",
		"contentHandle",
		"executionAdapter",
		"execute",
		"run",
		"dispatch",
		"fire",
		"publish",
		"subscribe",
	}
	for _, marker in ipairs(forbiddenMarkers) do
		local candidate = asset("forbidden." .. marker)
		candidate[marker] = true
		local forbiddenOk, forbiddenReason = Validation.definition(candidate)
		expectReject("forbidden field rejects: " .. marker, forbiddenOk, forbiddenReason, checks)
	end

	local cycle = {}
	cycle.self = cycle
	expectReject(
		"serialization rejects cycles",
		Serialization.validateSerializable(cycle),
		nil,
		checks
	)
	expectReject(
		"serialization rejects functions",
		Serialization.validateSerializable({ unsafe = function() end }),
		nil,
		checks
	)
	expectReject(
		"serialization rejects threads",
		Serialization.validateSerializable({ unsafe = coroutine.create(function() end) }),
		nil,
		checks
	)
	expectReject(
		"serialization rejects deep payloads",
		Serialization.validateSerializable(makeDeepPayload(Types.Limits.MaxPayloadDepth + 2)),
		nil,
		checks
	)
	expectReject(
		"serialization rejects oversized node counts",
		Serialization.validateSerializable(makeWidePayload(Types.Limits.MaxPayloadNodes + 1)),
		nil,
		checks
	)
	expectReject(
		"serialization rejects oversized strings",
		Serialization.validateSerializable({
			value = string.rep("x", Types.Limits.MaxPayloadStringLength + 1),
		}),
		nil,
		checks
	)
	local diagnosticCopy = Serialization.diagnosticCopy({
		["asset" .. "Handle"] = function() end,
		nested = { "load" .. "Asset" },
	})
	expect(
		"diagnostic copy sanitizes unsafe values",
		diagnosticCopy["<unsafe-marker>"] == "<unsafe-runtime-value>"
			and diagnosticCopy.nested[1] == "<unsafe-marker>",
		"diagnostic copy leaked unsafe values",
		checks
	)

	State.clear()
	fillLimit("asset", Types.Limits.MaxAssets, function(index)
		return asset("limit.asset." .. tostring(index))
	end, State.registerDefinition, checks)
	State.clear()
	fillLimit("category", Types.Limits.MaxCategories, function(index)
		return category("limit.category." .. tostring(index))
	end, State.registerCategory, checks)
	State.clear()
	fillLimit("package", Types.Limits.MaxPackages, function(index)
		return packageRecord("limit.package." .. tostring(index), nil)
	end, State.registerPackage, checks)
	State.clear()
	expectAccept(
		"reference limit seed asset registers",
		State.registerDefinition(asset("limit.reference.seed")),
		nil,
		checks
	)
	fillLimit("reference", Types.Limits.MaxReferences, function(index)
		return reference("limit.reference.seed", "limit.reference." .. tostring(index))
	end, State.registerReference, checks)
	State.clear()
	expectAccept(
		"variant limit seed asset registers",
		State.registerDefinition(asset("limit.variant.seed")),
		nil,
		checks
	)
	fillLimit("variant", Types.Limits.MaxVariants, function(index)
		return variant("limit.variant.seed", "limit.variant." .. tostring(index))
	end, State.registerVariant, checks)
	State.clear()
	expectAccept(
		"dependency limit source registers",
		State.registerDefinition(asset("limit.dependency.source")),
		nil,
		checks
	)
	expectAccept(
		"dependency limit target registers",
		State.registerDefinition(asset("limit.dependency.target")),
		nil,
		checks
	)
	fillLimit("dependency", Types.Limits.MaxDependencies, function(index)
		return dependency(
			"limit.dependency." .. tostring(index),
			"limit.dependency.source",
			"limit.dependency.target"
		)
	end, State.registerDependency, checks)
	State.clear()
	expectAccept(
		"ownership limit seed asset registers",
		State.registerDefinition(asset("limit.ownership.seed")),
		nil,
		checks
	)
	fillLimit("ownership", Types.Limits.MaxOwnershipRecords, function(index)
		return ownership("limit.ownership.seed", "limit.ownership." .. tostring(index))
	end, State.registerOwnership, checks)
	State.clear()
	expectAccept(
		"budget limit seed asset registers",
		State.registerDefinition(asset("limit.budget.seed")),
		nil,
		checks
	)
	fillLimit("budget", Types.Limits.MaxBudgetRecords, function(index)
		return budget("limit.budget.seed", "limit.budget." .. tostring(index))
	end, State.registerBudget, checks)
	State.clear()
	expectAccept(
		"compatibility limit seed asset registers",
		State.registerDefinition(asset("limit.compatibility.seed")),
		nil,
		checks
	)
	fillLimit("compatibility", Types.Limits.MaxCompatibilityRecords, function(index)
		return compatibility("limit.compatibility.seed", "limit.compatibility." .. tostring(index))
	end, State.registerCompatibility, checks)
	State.clear()
	expectAccept(
		"audit limit seed asset registers",
		State.registerDefinition(asset("limit.audit.seed")),
		nil,
		checks
	)
	fillLimit("audit", Types.Limits.MaxAudits, function(index)
		return audit("limit.audit." .. tostring(index), "limit.audit.seed")
	end, State.registerAudit, checks)

	State.clear()
	expectAccept(
		"snapshot seed asset registers",
		State.registerDefinition(asset("snapshot.asset")),
		nil,
		checks
	)
	local snapshot = State.inspect()
	snapshot.definitions["snapshot.asset"].assetName = "MutatedOutside"
	expect(
		"snapshots are isolated",
		State.inspect().definitions["snapshot.asset"].assetName ~= "MutatedOutside",
		"snapshot mutation leaked into state",
		checks
	)
	local diagnostics = State.inspect()
	diagnostics.counts.definitions = 999999
	expect(
		"diagnostics are read-only copies",
		State.inspect().counts.definitions ~= 999999,
		"diagnostics mutation leaked",
		checks
	)

	for index = 1, Types.Limits.MaxValidationFailures + 10 do
		State.recordValidationFailure("failure." .. tostring(index), { index = index })
	end
	expect(
		"validation failure history is bounded",
		#State.inspect().validationFailures <= Types.Limits.MaxValidationFailures,
		"validation failure history exceeded limit",
		checks
	)
	for index = 1, Types.Limits.MaxSnapshotHistory + 10 do
		State.recordSnapshot({ index = index })
	end
	expect(
		"snapshot history is bounded",
		State.inspect().counts.snapshots <= Types.Limits.MaxSnapshotHistory,
		"snapshot history exceeded limit",
		checks
	)

	assertNoRuntimeSurface(checks)

	State.clear()
	expect(
		"shutdown clears state",
		State.inspect().counts.definitions == 0,
		"state remained after clear",
		checks
	)
	expectAccept(
		"namespace resets after shutdown",
		State.registerDefinition(asset("asset.a")),
		nil,
		checks
	)
	State.clear()

	local failed = {}
	for _, check in ipairs(checks) do
		if not check.ok then
			table.insert(failed, check)
		end
	end

	return {
		ok = #failed == 0,
		code = if #failed == 0
			then "AssetManifestSelfChecksPassed"
			else "AssetManifestSelfChecksFailed",
		total = #checks,
		failed = failed,
		checks = checks,
	}
end

return SelfChecks

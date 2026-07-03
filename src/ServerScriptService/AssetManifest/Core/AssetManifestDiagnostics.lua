--!strict
-- Health-only diagnostics for the Asset Manifest schema runtime.

local State = require(script.Parent.AssetManifestState)
local Types = require(script.Parent.AssetManifestTypes)

local Diagnostics = {}

local function limitUsage(count: number, limit: number)
	return { count = count, limit = limit, remaining = math.max(limit - count, 0) }
end

function Diagnostics.capture(lifecycle: any, dependencies: any)
	local state = State.inspect()
	local counts = state.counts
	local validationOk, validationReason = dependencies.Validation.validate()
	return {
		initialized = lifecycle.initialized,
		started = lifecycle.started,
		lifecycleState = if lifecycle.started
			then "Started"
			elseif lifecycle.initialized then "Initialized"
			else "Cold",
		health = if validationOk then "Healthy" else "Unhealthy",
		validationOk = validationOk,
		validationReason = validationReason,
		assetCount = counts.definitions,
		categoryCount = counts.categories,
		packageCount = counts.packages,
		referenceCount = counts.references,
		variantCount = counts.variants,
		dependencyCount = counts.dependencies,
		ownershipCount = counts.ownership,
		budgetCount = counts.budgets,
		compatibilityCount = counts.compatibility,
		auditCount = counts.audits,
		validationFailureCount = counts.validationFailures,
		snapshotCount = counts.snapshots,
		counts = counts,
		limitUsage = {
			assets = limitUsage(counts.definitions, Types.Limits.MaxAssets),
			categories = limitUsage(counts.categories, Types.Limits.MaxCategories),
			packages = limitUsage(counts.packages, Types.Limits.MaxPackages),
			references = limitUsage(counts.references, Types.Limits.MaxReferences),
			variants = limitUsage(counts.variants, Types.Limits.MaxVariants),
			dependencies = limitUsage(counts.dependencies, Types.Limits.MaxDependencies),
			ownership = limitUsage(counts.ownership, Types.Limits.MaxOwnershipRecords),
			budgets = limitUsage(counts.budgets, Types.Limits.MaxBudgetRecords),
			compatibility = limitUsage(counts.compatibility, Types.Limits.MaxCompatibilityRecords),
			audits = limitUsage(counts.audits, Types.Limits.MaxAudits),
		},
		runtimeLimits = Types.Limits,
		serializationPosture = "rejects unsafe runtime values, cycles, deep payloads, oversized strings, and oversized node counts",
		snapshotIsolationProof = "snapshots are deep copied schema data",
		diagnosticsIsolationProof = "diagnostics are deep copied health data",
		assetManifestIntegrityPosture = "manifest records only",
		assetDefinitionIntegrityPosture = "asset definitions are records only",
		categoryIntegrityPosture = "categories are taxonomy only",
		packageIntegrityPosture = "packages are manifest groups only",
		referenceIntegrityPosture = "references are symbolic or id/path records only",
		variantIntegrityPosture = "variants are metadata only",
		dependencyIntegrityPosture = "dependencies are metadata only",
		ownershipIntegrityPosture = "ownership records are documentation only",
		budgetIntegrityPosture = "budgets are declared constraints only",
		compatibilityIntegrityPosture = "compatibility records are metadata only",
		auditIntegrityPosture = "audits are review summaries only",
		noLoadingPosture = {
			noAssetLoad = true,
			noAssetPreload = true,
			noContentBoundaryRun = true,
			noInsertBoundaryRun = true,
			noMarketplaceBoundaryRun = true,
			noAnimationLoad = true,
			noSoundLoad = true,
			noMeshLoad = true,
			noTextureLoad = true,
			noMaterialLoad = true,
			noDecalLoad = true,
			noModelSpawn = true,
			noMeshInsert = true,
			noTextureApply = true,
			noMaterialApply = true,
			noDecalApply = true,
			noParticleOrVfxCreate = true,
			noUiCreate = true,
			noUiLoad = true,
			noFontLoad = true,
			noLocalizationLoad = true,
			noContentStreaming = true,
			noMapLoad = true,
			noRoomLoad = true,
		},
		noExecutionPosture = {
			noWorkspaceChange = true,
			noReplicatedStorageChange = true,
			noServerStorageChange = true,
			noRemotes = true,
			noClientAuthority = true,
			noRuntimeOrchestration = true,
			noGameplayRun = true,
			noPresentationRun = true,
			noSaveRun = true,
			noStorageReadsWrites = true,
			noHttpLayer = true,
			noMessagingLayer = true,
			noMetricsCollection = true,
			noSignalExport = true,
			noChapterContent = true,
			noFinalStory = true,
			noFinalDialogue = true,
			noCutscenes = true,
		},
		recentValidationFailures = state.validationFailures,
		lastSelfCheckResult = lifecycle.lastSelfChecks,
	}
end

function Diagnostics.validate(dependencies: any): (boolean, string?)
	local ok, reason = dependencies.Validation.validate()
	if not ok then
		return false, reason
	end
	return true, nil
end

return Diagnostics

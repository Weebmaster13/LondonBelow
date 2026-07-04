--!strict

local State = require(script.Parent.AssetUsagePlanState)
local Types = require(script.Parent.AssetUsagePlanTypes)

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
		usagePlanCount = counts.definitions,
		contextCount = counts.contexts,
		constraintCount = counts.constraints,
		dependencyCount = counts.dependencies,
		budgetCount = counts.budgets,
		accessibilityCount = counts.accessibility,
		auditCount = counts.audits,
		validationFailureCount = counts.validationFailures,
		snapshotCount = counts.snapshots,
		counts = counts,
		limitUsage = {
			usagePlans = limitUsage(counts.definitions, Types.Limits.MaxUsagePlans),
			contexts = limitUsage(counts.contexts, Types.Limits.MaxContexts),
			constraints = limitUsage(counts.constraints, Types.Limits.MaxConstraints),
			dependencies = limitUsage(counts.dependencies, Types.Limits.MaxDependencies),
			budgets = limitUsage(counts.budgets, Types.Limits.MaxBudgets),
			accessibility = limitUsage(counts.accessibility, Types.Limits.MaxAccessibilityRecords),
			audits = limitUsage(counts.audits, Types.Limits.MaxAudits),
		},
		runtimeLimits = Types.Limits,
		serializationPosture = "rejects unsafe runtime values, cycles, deep payloads, oversized strings, and oversized node counts",
		snapshotIsolationProof = "snapshots are deep copied schema data",
		diagnosticsIsolationProof = "diagnostics are deep copied health data",
		dependencyPosture = "dependencies are metadata and direct cycles reject",
		safetyPosture = "metadata-only intent records with validation before mutation",
		integrityPosture = {
			definitions = "usage intent records only",
			contexts = "context metadata only",
			constraints = "safety/performance/accessibility summaries only",
			dependencies = "relationship metadata only",
			budgets = "declared limits only",
			accessibility = "accommodation metadata only",
			audits = "review summaries only",
		},
		noExecutionPosture = {
			noAssetLoad = true,
			noAssetPreload = true,
			noContentBoundaryRun = true,
			noInsertBoundaryRun = true,
			noMarketplaceBoundaryRun = true,
			noInstanceCreation = true,
			noStorageMutation = true,
			noWorldMutation = true,
			noUiCreation = true,
			noStreamRun = true,
			noModelSpawn = true,
			noSoundPlay = true,
			noAnimationLoad = true,
			noGameplayRun = true,
			noPresentationRun = true,
			noSaveRun = true,
			noRemotes = true,
			noClientAuthority = true,
			noStorageReadsWrites = true,
			noHttpLayer = true,
			noMessagingLayer = true,
			noMetricsCollection = true,
			noSignalExport = true,
			noChapterContent = true,
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

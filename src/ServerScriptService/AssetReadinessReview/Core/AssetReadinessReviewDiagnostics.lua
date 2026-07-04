--!strict

local State = require(script.Parent.AssetReadinessReviewState)
local Types = require(script.Parent.AssetReadinessReviewTypes)

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
		checklistCount = counts.checklists,
		findingCount = counts.findings,
		gateCount = counts.gates,
		decisionCount = counts.decisions,
		auditCount = counts.audits,
		validationFailureCount = counts.validationFailures,
		snapshotCount = counts.snapshots,
		counts = counts,
		limitUsage = {
			checklists = limitUsage(counts.checklists, Types.Limits.MaxChecklists),
			findings = limitUsage(counts.findings, Types.Limits.MaxFindings),
			gates = limitUsage(counts.gates, Types.Limits.MaxGates),
			decisions = limitUsage(counts.decisions, Types.Limits.MaxDecisions),
			audits = limitUsage(counts.audits, Types.Limits.MaxAudits),
		},
		runtimeLimits = Types.Limits,
		serializationPosture = "rejects unsafe runtime values, cycles, deep payloads, oversized strings, and oversized node counts",
		readinessPosture = "metadata-only review of manifest and usage plan readiness",
		snapshotIsolationProof = "snapshots are isolated deep copies of schema metadata",
		diagnosticsIsolationProof = "diagnostics expose health-only copied state",
		integrityPosture = {
			checklists = "readiness review summaries only",
			findings = "review findings only",
			gates = "gate evidence only",
			decisions = "review decisions only",
			audits = "audit records only",
		},
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
		},
		noExecutionPosture = {
			noInstanceCreation = true,
			noStorageMutation = true,
			noWorldMutation = true,
			noUiCreation = true,
			noVfxCreation = true,
			noStreamRun = true,
			noModelSpawn = true,
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
	return dependencies.Validation.validate()
end

return Diagnostics

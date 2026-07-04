--!strict

local State = require(script.Parent.AssetExecutionImplementationReadinessState)
local Types = require(script.Parent.AssetExecutionImplementationReadinessTypes)

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
		readinessCount = counts.readinessRecords,
		checklistCount = counts.checklists,
		gapCount = counts.gaps,
		auditCount = counts.audits,
		validationFailureCount = counts.validationFailures,
		snapshotCount = counts.snapshots,
		counts = counts,
		limitUsage = {
			readinessRecords = limitUsage(
				counts.readinessRecords,
				Types.Limits.MaxReadinessRecords
			),
			checklists = limitUsage(counts.checklists, Types.Limits.MaxChecklists),
			gaps = limitUsage(counts.gaps, Types.Limits.MaxGaps),
			audits = limitUsage(counts.audits, Types.Limits.MaxAudits),
		},
		runtimeLimits = Types.Limits,
		serializationPosture = "rejects unsafe runtime values, cycles, deep payloads, oversized strings, and oversized node counts",
		implementationReadinessPosture = "schema-only implementation readiness evidence; readiness records do not grant client authority or execute assets",
		snapshotIsolationProof = "snapshots are isolated deep copies of schema metadata",
		diagnosticsIsolationProof = "diagnostics expose health-only copied state",
		integrityPosture = {
			readinessRecords = "implementation readiness evidence records only",
			checklists = "implementation readiness checklist records only",
			gaps = "implementation readiness gap records only",
			audits = "implementation readiness audit records only",
		},
		noLoadingPosture = {
			noAssetLoad = true,
			noAssetPreload = true,
			noAssetStreaming = true,
			noAssetApplication = true,
			noAssetPlayback = true,
			noContentServiceRun = true,
			noCatalogInsertRun = true,
			noMarketplaceRun = true,
		},
		noExecutionPosture = {
			noInstanceCreation = true,
			noStorageMutation = true,
			noWorldMutation = true,
			noUiCreation = true,
			noVfxCreation = true,
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

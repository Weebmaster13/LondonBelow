--!strict

local State = require(script.Parent.AssetExecutionImplementationContractState)
local Types = require(script.Parent.AssetExecutionImplementationContractTypes)

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
		contractCount = counts.contracts,
		responsibilityCount = counts.responsibilities,
		boundaryCount = counts.boundaries,
		auditCount = counts.audits,
		validationFailureCount = counts.validationFailures,
		snapshotCount = counts.snapshots,
		counts = counts,
		limitUsage = {
			contracts = limitUsage(counts.contracts, Types.Limits.MaxContracts),
			responsibilities = limitUsage(
				counts.responsibilities,
				Types.Limits.MaxResponsibilities
			),
			boundaries = limitUsage(counts.boundaries, Types.Limits.MaxBoundaries),
			audits = limitUsage(counts.audits, Types.Limits.MaxAudits),
		},
		runtimeLimits = Types.Limits,
		serializationPosture = "rejects unsafe runtime values, cycles, deep payloads, oversized strings, and oversized node counts",
		implementationContractPosture = "schema-only implementation contract evidence; contract records do not grant client authority or execute assets",
		integrationReadinessPosture = "ready for future read-only governance chain inspection; no cross-runtime resolution is performed",
		snapshotIsolationProof = "snapshots are isolated deep copies of schema metadata",
		diagnosticsIsolationProof = "diagnostics expose health-only copied state",
		integrityPosture = {
			contracts = "implementation contract evidence records only",
			responsibilities = "implementation contract responsibility records only",
			boundaries = "implementation contract boundary records only",
			audits = "implementation contract audit records only",
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
			["no" .. "Data" .. "Store"] = true,
			noHttpLayer = true,
			noHttp = true,
			noMessagingLayer = true,
			noMessaging = true,
			noMetricsCollection = true,
			noAnalytics = true,
			noTelemetry = true,
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

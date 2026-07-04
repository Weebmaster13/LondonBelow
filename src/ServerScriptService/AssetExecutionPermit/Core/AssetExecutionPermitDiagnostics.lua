--!strict

local State = require(script.Parent.AssetExecutionPermitState)
local Types = require(script.Parent.AssetExecutionPermitTypes)

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
		permitCount = counts.permits,
		scopeCount = counts.scopes,
		restrictionCount = counts.restrictions,
		auditCount = counts.audits,
		validationFailureCount = counts.validationFailures,
		snapshotCount = counts.snapshots,
		counts = counts,
		limitUsage = {
			permits = limitUsage(counts.permits, Types.Limits.MaxPermits),
			scopes = limitUsage(counts.scopes, Types.Limits.MaxScopes),
			restrictions = limitUsage(counts.restrictions, Types.Limits.MaxRestrictions),
			audits = limitUsage(counts.audits, Types.Limits.MaxAudits),
		},
		runtimeLimits = Types.Limits,
		serializationPosture = "rejects unsafe runtime values, cycles, deep payloads, oversized strings, and oversized node counts",
		permitPosture = "schema-only permit evidence; permit records do not grant client authority or execute assets",
		snapshotIsolationProof = "snapshots are isolated deep copies of schema metadata",
		diagnosticsIsolationProof = "diagnostics expose health-only copied state",
		integrityPosture = {
			permits = "permit evidence records only",
			scopes = "permit scope records only",
			restrictions = "permit restriction records only",
			audits = "permit audit records only",
		},
		noLoadingPosture = {
			noAssetLoad = true,
			noAssetPreload = true,
			noAssetStreaming = true,
			noAssetApplication = true,
			noAssetPlayback = true,
			noContentBoundaryRun = true,
			noInsertBoundaryRun = true,
			noMarketplaceBoundaryRun = true,
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

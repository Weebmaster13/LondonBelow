--!strict

local State = require(script.Parent.AssetApprovalLedgerState)
local Types = require(script.Parent.AssetApprovalLedgerTypes)

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
		approvalCount = counts.approvals,
		conditionCount = counts.conditions,
		revocationCount = counts.revocations,
		auditCount = counts.audits,
		validationFailureCount = counts.validationFailures,
		snapshotCount = counts.snapshots,
		counts = counts,
		limitUsage = {
			approvals = limitUsage(counts.approvals, Types.Limits.MaxApprovals),
			conditions = limitUsage(counts.conditions, Types.Limits.MaxConditions),
			revocations = limitUsage(counts.revocations, Types.Limits.MaxRevocations),
			audits = limitUsage(counts.audits, Types.Limits.MaxAudits),
		},
		runtimeLimits = Types.Limits,
		serializationPosture = "rejects unsafe runtime values, cycles, deep payloads, oversized strings, and oversized node counts",
		approvalPosture = "schema-only approval evidence; approval records do not grant execution",
		snapshotIsolationProof = "snapshots are isolated deep copies of schema metadata",
		diagnosticsIsolationProof = "diagnostics expose health-only copied state",
		integrityPosture = {
			approvals = "approval evidence records only",
			conditions = "approval condition records only",
			revocations = "approval revocation records only",
			audits = "approval audit records only",
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

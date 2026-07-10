--!strict

local State = require(script.Parent.AssetGovernanceIntegrationState)
local Types = require(script.Parent.AssetGovernanceIntegrationTypes)

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
		counts = counts,
		limitUsage = {
			chains = limitUsage(counts.chains, Types.Limits.MaxChains),
			runtimeNodes = limitUsage(counts.runtimeNodes, Types.Limits.MaxRuntimeNodes),
			referenceReviews = limitUsage(
				counts.referenceReviews,
				Types.Limits.MaxReferenceReviews
			),
			audits = limitUsage(counts.audits, Types.Limits.MaxAudits),
		},
		runtimeLimits = Types.Limits,
		assetGovernanceIntegrationPosture = "read-only asset governance chain integration metadata",
		readOnlyIntegrationPosture = "inspects copied health and snapshot evidence only; no repair or mutation",
		noLoadingPosture = {
			noAssetLoad = true,
			noAssetPreload = true,
			noAssetStreaming = true,
			noContentServiceRun = true,
			noCatalogInsertRun = true,
			noMarketplaceRun = true,
		},
		noExecutionPosture = {
			noAssetApplication = true,
			noAssetPlayback = true,
			noModelSpawn = true,
			noUiCreation = true,
			noVfxCreation = true,
			noRemotes = true,
			noClientAuthority = true,
			["no" .. "Data" .. "Store"] = true,
			noHttp = true,
			noMessaging = true,
			noAnalytics = true,
			noTelemetry = true,
			noGameplayRun = true,
			noPresentationRun = true,
			noSaveRun = true,
			noChapterContent = true,
		},
		noMutationPosture = {
			noWorldMutation = true,
			noStorageMutation = true,
			noUpstreamMutation = true,
			noRepairMutation = true,
		},
		providerReadinessPosture = Types.RuntimeProviderName,
		chainOrderPosture = Types.RuntimeOrder,
		diagnosticsIsolationProof = "diagnostics expose copied health-only metadata",
		snapshotIsolationProof = "snapshots are isolated deep copies of integration metadata",
		recentValidationFailures = state.validationFailures,
		lastSelfCheckResult = lifecycle.lastSelfChecks,
	}
end

function Diagnostics.validate(dependencies: any): (boolean, string?)
	return dependencies.Validation.validate()
end

return Diagnostics

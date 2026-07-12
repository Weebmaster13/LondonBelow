--!strict

local Serialization = require(script.Parent.AssetExecutionAdapterSerialization)
local State = require(script.Parent.AssetExecutionAdapterState)
local Types = require(script.Parent.AssetExecutionAdapterTypes)

local Diagnostics = {}

local function limitUsage(count: number, limit: number)
	return { count = count, limit = limit, remaining = math.max(limit - count, 0) }
end

local function noAuthorityPosture()
	return {
		noExecution = true,
		noAssetLoading = true,
		noAssetPreloading = true,
		noAssetStreaming = true,
		noAssetSpawning = true,
		noAssetApplication = true,
		noAssetPlayback = true,
		noAnimationPlayback = true,
		noAudioPlayback = true,
		noModelCreation = true,
		noUi = true,
		noVfx = true,
		noWorldMutation = true,
		noStorageMutation = true,
		noClientAuthority = true,
		noNetworkOwnership = true,
		noPhysics = true,
		noRouting = true,
		noDispatch = true,
		noQueues = true,
		noScheduler = true,
		noOrchestration = true,
		noPersistence = true,
		noHttp = true,
		noMessaging = true,
		noAnalytics = true,
		noTelemetry = true,
		noGameplay = true,
		noPresentation = true,
		noSave = true,
		noChapter = true,
	}
end

local function posture()
	return {
		assetExecutionAdapterRuntimePosture = "adapter runtime stores metadata records only",
		assetExecutionAdapterValidationPosture = "validation occurs before mutation",
		assetExecutionAdapterCompatibilityPosture = "compatibility records are metadata only",
		assetExecutionAdapterLifecyclePosture = "lifecycle metadata does not execute adapter work",
		assetExecutionAdapterCapabilityPosture = "capabilities describe future obligations only",
		assetExecutionAdapterBoundaryPosture = "boundaries prohibit executable surfaces",
		assetExecutionAdapterAuditPosture = "audits summarize copied metadata only",
		assetExecutionAdapterCertificationPosture = "adapter runtime foundation is non-executing",
		assetExecutionAdapterSchemaPosture = "schema fields are exact and closed",
		assetExecutionAdapterEnumPosture = "enum values are exact and closed",
		assetExecutionAdapterReferencePosture = "references are parent checked before mutation",
		assetExecutionAdapterArrayPosture = "child arrays are ordered and duplicate free",
		assetExecutionAdapterLimitPosture = "runtime limits match certified values",
		assetExecutionAdapterSignalPosture = "signal names are metadata only",
		assetExecutionAdapterCoordinatorBoundaryPosture = "coordinator API exposes metadata only",
		assetExecutionAdapterIsolationPosture = "diagnostics expose deep copies only",
		assetExecutionAdapterNoImplementationPosture = "adapter implementations are not stored",
		assetExecutionAdapterNoRegistryPosture = "no live registry is exposed",
		assetExecutionAdapterNoOperationPosture = "no asset operation surface is present",
		assetExecutionAdapterNoAuthorityPosture = "adapter metadata grants no authority",
		noExecution = true,
		noAssetLoading = true,
		noGameplay = true,
		noPresentation = true,
		noSave = true,
		noNetworking = true,
		noAnalytics = true,
		noTelemetry = true,
	}
end

function Diagnostics.capture(lifecycle: any, dependencies: any)
	local state = State.inspect()
	local counts = state.counts
	local validationOk, validationReason = dependencies.Validation.validate()
	local report = {
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
			adapters = limitUsage(counts.adapters, Types.Limits.MaxAdapters),
			capabilities = limitUsage(counts.capabilities, Types.Limits.MaxCapabilities),
			compatibilities = limitUsage(counts.compatibilities, Types.Limits.MaxCompatibilities),
			boundaries = limitUsage(counts.boundaries, Types.Limits.MaxBoundaries),
			audits = limitUsage(counts.audits, Types.Limits.MaxAudits),
		},
		runtimeLimits = Serialization.deepCopy(Types.Limits),
		runtimeName = Types.RuntimeName,
		coordinatorName = Types.CoordinatorName,
		providerPosture = Types.RuntimeProviderName,
		snapshotPosture = Types.SnapshotKind,
		documentationPosture = Serialization.deepCopy(Types.DocumentationFiles),
		bootstrapPosture = Serialization.deepCopy(Types.BootstrapDependencyOrder),
		governanceSnapshotProviders = Serialization.deepCopy(Types.GovernanceSnapshotProviders),
		noAuthorityPosture = noAuthorityPosture(),
		postureKeys = Serialization.deepCopy(Types.PostureKeys),
		schemas = {
			adapters = state.adapters,
			capabilities = state.capabilities,
			compatibilities = state.compatibilities,
			boundaries = state.boundaries,
			audits = state.audits,
		},
		recentValidationFailures = state.validationFailures,
		lastSelfCheckResult = Serialization.diagnosticCopy(lifecycle.lastSelfChecks),
	}
	for key, value in pairs(posture()) do
		report[key] = value
	end
	return report
end

function Diagnostics.validate(dependencies: any): (boolean, string?)
	return dependencies.Validation.validate()
end

return Diagnostics

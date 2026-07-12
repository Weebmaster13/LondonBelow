--!strict

local State = require(script.Parent.AssetExecutionAdapterState)
local Types = require(script.Parent.AssetExecutionAdapterTypes)

local Snapshots = {}

local function noAuthorityPosture()
	return {
		noExecution = true,
		noAssetLoading = true,
		noAssetSpawning = true,
		noAssetPlayback = true,
		noWorldMutation = true,
		noClientAuthority = true,
		noNetworking = true,
		noRouting = true,
		noDispatch = true,
		noQueues = true,
		noScheduler = true,
		noOrchestration = true,
		noGameplay = true,
		noPresentation = true,
		noSave = true,
		noChapter = true,
	}
end

function Snapshots.capture(lifecycle: any, dependencies: any)
	local state = State.inspect()
	local snapshot = {
		kind = Types.SnapshotKind,
		mode = Types.Mode,
		initialized = lifecycle.initialized,
		started = lifecycle.started,
		counts = state.counts,
		runtimeLimits = dependencies.Serialization.deepCopy(Types.Limits),
		runtimeName = Types.RuntimeName,
		coordinatorName = Types.CoordinatorName,
		providerPosture = Types.RuntimeProviderName,
		snapshotPosture = Types.SnapshotKind,
		documentationPosture = dependencies.Serialization.deepCopy(Types.DocumentationFiles),
		bootstrapPosture = dependencies.Serialization.deepCopy(Types.BootstrapDependencyOrder),
		governanceSnapshotProviders = dependencies.Serialization.deepCopy(
			Types.GovernanceSnapshotProviders
		),
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
		assetExecutionAdapterIsolationPosture = "snapshots expose deep copies only",
		assetExecutionAdapterNoImplementationPosture = "adapter implementations are not stored",
		assetExecutionAdapterNoRegistryPosture = "no live registry is exposed",
		assetExecutionAdapterNoOperationPosture = "no asset operation surface is present",
		assetExecutionAdapterNoAuthorityPosture = "adapter metadata grants no authority",
		noAuthorityPosture = noAuthorityPosture(),
		noExecution = true,
		noAssetLoading = true,
		noGameplay = true,
		noPresentation = true,
		noSave = true,
		noNetworking = true,
		noAnalytics = true,
		noTelemetry = true,
		postureKeys = dependencies.Serialization.deepCopy(Types.PostureKeys),
		schemas = {
			adapters = state.adapters,
			capabilities = state.capabilities,
			compatibilities = state.compatibilities,
			boundaries = state.boundaries,
			audits = state.audits,
		},
		validationFailures = state.validationFailures,
	}
	State.recordSnapshot(snapshot)
	return dependencies.Serialization.deepCopy(snapshot)
end

return Snapshots

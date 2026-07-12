--!strict

local State = require(script.Parent.AssetExecutionState)
local Types = require(script.Parent.AssetExecutionTypes)

local Snapshots = {}

local function noAuthorityPosture()
	return {
		noExecution = true,
		noAssetLoading = true,
		noAssetStreaming = true,
		noAssetSpawning = true,
		noAssetApplication = true,
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
		assetExecutionRuntimePosture = "execution runtime metadata only",
		assetExecutionRequestPosture = "requests are metadata only",
		assetExecutionBoundaryPosture = "boundaries describe prohibited surfaces only",
		assetExecutionAuditPosture = "audits summarize copied metadata only",
		assetExecutionIntegrationReadinessPosture = "integration readiness is copied metadata only",
		assetExecutionCompatibilityPosture = "compatibility declarations are static evidence only",
		assetExecutionIntegrationHardeningPosture = "integration hardening validates exact static declarations",
		assetExecutionDeclarationExactnessPosture = "integration declaration fields and values are exact",
		assetExecutionDeclarationOrderingPosture = "integration declaration order is deterministic",
		assetExecutionCompatibilityIdentityPosture = "compatibility identities are exact metadata",
		assetExecutionOrderTablePosture = "integration order tables are exact and copied",
		assetExecutionMetadataExactnessPosture = "integration metadata is exact copied evidence",
		assetExecutionEvidenceExactnessPosture = "integration evidence arrays are exact copied evidence",
		assetExecutionTagExactnessPosture = "integration tag arrays are exact copied evidence",
		assetExecutionAdapterContaminationPosture = "adapter contamination is rejected",
		assetExecutionOperationContaminationPosture = "asset operation contamination is rejected",
		assetExecutionIntegrationLimitIsolationPosture = "integration readiness uses certified runtime limits",
		assetExecutionIntegrationDocumentationConsistencyPosture = "integration documentation references are exact",
		assetExecutionSchemaPosture = "schema fields are exact and closed",
		assetExecutionEnumPosture = "enum values are exact and closed",
		assetExecutionReferencePosture = "references are parent checked before mutation",
		assetExecutionArrayPosture = "child arrays are ordered and duplicate free",
		assetExecutionLimitPosture = "runtime limits match certified values",
		assetExecutionSignalPosture = "signal names are metadata only",
		assetExecutionCoordinatorBoundaryPosture = "coordinator API exposes metadata only",
		assetExecutionFutureAdapterSeparationPosture = "future adapters remain absent",
		assetExecutionFutureAssetOperationSeparationPosture = "future asset operations remain absent",
		assetExecutionFutureGameplaySeparationPosture = "future gameplay integration remains absent",
		assetExecutionIsolationPosture = "snapshots expose deep copies only",
		assetExecutionValidationPosture = "validation occurs before mutation",
		assetExecutionLifecyclePosture = "lifecycle state is metadata only",
		assetExecutionNoAuthorityPosture = "runtime has no execution authority",
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
		integrationReadiness = {
			declarationCount = #Types.AssetExecutionIntegrationReadinessDeclarations,
			declarations = dependencies.Serialization.deepCopy(
				Types.AssetExecutionIntegrationReadinessDeclarations
			),
			order = dependencies.Serialization.deepCopy(Types.IntegrationReadinessDeclarationOrder),
			fields = dependencies.Serialization.deepCopy(
				Types.IntegrationReadinessDeclarationFields
			),
		},
		schemas = {
			runtimes = state.runtimes,
			requests = state.requests,
			boundaries = state.boundaries,
			audits = state.audits,
		},
		validationFailures = state.validationFailures,
	}
	State.recordSnapshot(snapshot)
	return dependencies.Serialization.deepCopy(snapshot)
end

return Snapshots

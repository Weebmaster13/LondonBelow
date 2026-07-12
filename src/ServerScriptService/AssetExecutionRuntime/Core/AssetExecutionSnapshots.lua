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
		assetExecutionAdapterReadinessPosture = "adapter readiness is copied metadata only",
		assetExecutionAdapterCompatibilityPosture = "adapter compatibility declarations are static evidence only",
		assetExecutionAdapterIdentityPosture = "future adapter identities remain explicitly absent",
		assetExecutionAdapterAuthorityPosture = "adapter readiness grants no execution authority",
		assetExecutionAdapterBoundaryPosture = "adapter readiness declares separation boundaries only",
		assetExecutionAdapterLifecyclePosture = "adapter lifecycle remains absent and separate",
		assetExecutionAdapterSerializationPosture = "adapter readiness serialization is copied metadata only",
		assetExecutionAdapterIsolationPosture = "adapter readiness snapshots expose deep copies only",
		assetExecutionAdapterLimitPosture = "adapter readiness uses certified runtime limits",
		assetExecutionAdapterDocumentationPosture = "adapter readiness documentation references are exact",
		assetExecutionNoLiveAdapterPosture = "no active adapter surface is present",
		assetExecutionNoAssetOperationPosture = "no asset operation surface is present",
		assetExecutionAdapterHardeningPosture = "adapter readiness hardening validates certified static declarations",
		assetExecutionAdapterIdentityHardeningPosture = "adapter readiness identities reject aliases",
		assetExecutionAdapterBoundaryHardeningPosture = "adapter readiness boundaries reject drift",
		assetExecutionAdapterDocumentationHardeningPosture = "adapter readiness documentation references reject drift",
		assetExecutionAdapterSerializationHardeningPosture = "adapter readiness serialization rejects unsafe markers",
		assetExecutionAdapterValidationHardeningPosture = "adapter readiness validation is non-mutating",
		assetExecutionAdapterIsolationHardeningPosture = "adapter readiness copied tables are isolated",
		assetExecutionAdapterLimitHardeningPosture = "adapter readiness limits match certified runtime limits",
		assetExecutionAdapterGovernanceHardeningPosture = "adapter readiness governance provider is exact",
		assetExecutionAdapterBootstrapHardeningPosture = "adapter readiness Bootstrap dependency is exact",
		assetExecutionAdapterContractPosture = "adapter contract readiness is copied metadata only",
		assetExecutionAdapterContractValidationPosture = "adapter contract validation uses certified declarations",
		assetExecutionAdapterContractIsolationPosture = "adapter contract snapshots expose deep copies only",
		assetExecutionAdapterContractBoundaryPosture = "adapter contract boundaries prohibit executable surfaces",
		assetExecutionAdapterContractDocumentationPosture = "adapter contract documentation references are exact",
		assetExecutionAdapterContractSerializationPosture = "adapter contract serialization rejects unsafe markers",
		assetExecutionAdapterContractLifecyclePosture = "adapter contract lifecycle remains absent",
		assetExecutionAdapterContractAuthorityPosture = "adapter contract grants no authority",
		assetExecutionAdapterContractOperationPosture = "adapter contract grants no asset operation permission",
		assetExecutionAdapterContractGovernancePosture = "adapter contract governance provider is exact",
		assetExecutionAdapterContractBootstrapPosture = "adapter contract Bootstrap dependency is exact",
		assetExecutionAdapterContractHardeningPosture = "adapter contract hardening freezes declaration count, order, and identity",
		assetExecutionAdapterContractValidationHardeningPosture = "adapter contract hardening validates exact fields, enums, evidence, tags, and metadata",
		assetExecutionAdapterContractSerializationHardeningPosture = "adapter contract hardening rejects adapter, execution, asset operation, and runtime contamination",
		assetExecutionAdapterContractIsolationHardeningPosture = "adapter contract hardening exposes isolated deep copies only",
		assetExecutionAdapterContractBoundaryHardeningPosture = "adapter contract hardening rejects boundary drift",
		assetExecutionAdapterContractDocumentationHardeningPosture = "adapter contract hardening rejects documentation drift",
		assetExecutionAdapterContractGovernanceHardeningPosture = "adapter contract hardening rejects governance provider drift",
		assetExecutionAdapterContractBootstrapHardeningPosture = "adapter contract hardening rejects Bootstrap dependency drift",
		assetExecutionAdapterContractIdentityHardeningPosture = "adapter contract hardening rejects identity aliases, spacing, casing, prefixes, and suffixes",
		assetExecutionAdapterContractLifecycleHardeningPosture = "adapter contract hardening keeps adapter lifecycle absent",
		assetExecutionAdapterContractAuthorityHardeningPosture = "adapter contract hardening keeps authority absent",
		assetExecutionAdapterContractOperationHardeningPosture = "adapter contract hardening keeps asset operations absent",
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
		adapterReadiness = {
			declarationCount = #Types.AssetExecutionAdapterReadinessDeclarations,
			declarations = dependencies.Serialization.deepCopy(
				Types.AssetExecutionAdapterReadinessDeclarations
			),
			order = dependencies.Serialization.deepCopy(Types.AdapterReadinessDeclarationOrder),
			fields = dependencies.Serialization.deepCopy(Types.AdapterReadinessDeclarationFields),
		},
		adapterContract = {
			declarationCount = #Types.AssetExecutionAdapterContractDeclarations,
			declarations = dependencies.Serialization.deepCopy(
				Types.AssetExecutionAdapterContractDeclarations
			),
			order = dependencies.Serialization.deepCopy(Types.AdapterContractDeclarationOrder),
			fields = dependencies.Serialization.deepCopy(Types.AdapterContractDeclarationFields),
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

--!strict

local Serialization = require(script.Parent.AssetExecutionSerialization)
local State = require(script.Parent.AssetExecutionState)
local Types = require(script.Parent.AssetExecutionTypes)

local Diagnostics = {}

local function limitUsage(count: number, limit: number)
	return { count = count, limit = limit, remaining = math.max(limit - count, 0) }
end

local function noAuthorityPosture()
	return {
		noExecution = true,
		noAssetLoading = true,
		noAssetStreaming = true,
		noAssetSpawning = true,
		noAssetApplication = true,
		noAssetPlayback = true,
		noUi = true,
		noVfx = true,
		noAnimation = true,
		noAudio = true,
		noModelCreation = true,
		noWorldMutation = true,
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
			runtimes = limitUsage(counts.runtimes, Types.Limits.MaxRuntimes),
			requests = limitUsage(counts.requests, Types.Limits.MaxRequests),
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
		assetExecutionAdapterIsolationPosture = "adapter readiness diagnostics expose deep copies only",
		assetExecutionAdapterLimitPosture = "adapter readiness uses certified runtime limits",
		assetExecutionAdapterDocumentationPosture = "adapter readiness documentation references are exact",
		assetExecutionNoLiveAdapterPosture = "no active adapter surface is present",
		assetExecutionNoAssetOperationPosture = "no asset operation surface is present",
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
		assetExecutionIsolationPosture = "diagnostics expose deep copies only",
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
		postureKeys = Serialization.deepCopy(Types.PostureKeys),
		integrationReadiness = {
			declarationCount = #Types.AssetExecutionIntegrationReadinessDeclarations,
			declarations = Serialization.deepCopy(
				Types.AssetExecutionIntegrationReadinessDeclarations
			),
			order = Serialization.deepCopy(Types.IntegrationReadinessDeclarationOrder),
			fields = Serialization.deepCopy(Types.IntegrationReadinessDeclarationFields),
		},
		adapterReadiness = {
			declarationCount = #Types.AssetExecutionAdapterReadinessDeclarations,
			declarations = Serialization.deepCopy(Types.AssetExecutionAdapterReadinessDeclarations),
			order = Serialization.deepCopy(Types.AdapterReadinessDeclarationOrder),
			fields = Serialization.deepCopy(Types.AdapterReadinessDeclarationFields),
		},
		schemas = {
			runtimes = state.runtimes,
			requests = state.requests,
			boundaries = state.boundaries,
			audits = state.audits,
		},
		recentValidationFailures = state.validationFailures,
		lastSelfCheckResult = Serialization.diagnosticCopy(lifecycle.lastSelfChecks),
	}
end

function Diagnostics.validate(dependencies: any): (boolean, string?)
	return dependencies.Validation.validate()
end

return Diagnostics

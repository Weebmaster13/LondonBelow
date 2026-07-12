--!strict

local Serialization = require(script.Parent.AssetExecutionSerialization)
local Types = require(script.Parent.AssetExecutionTypes)

local Validation = {}

local EXPECTED_SCHEMA_FIELDS = {
	ExecutionRuntime = {
		"runtimeId",
		"authorizationId",
		"readinessId",
		"runtimeKind",
		"runtimeStatus",
		"providerName",
		"snapshotProviderName",
		"requestIds",
		"boundaryIds",
		"auditIds",
		"evidence",
		"tags",
		"metadata",
	},
	ExecutionRequest = {
		"requestId",
		"runtimeId",
		"requestKind",
		"requestStatus",
		"requestedBy",
		"evidence",
		"tags",
		"metadata",
	},
	ExecutionBoundary = {
		"boundaryId",
		"runtimeId",
		"boundaryKind",
		"boundaryStatus",
		"summary",
		"evidence",
		"tags",
		"metadata",
	},
	ExecutionAudit = {
		"auditId",
		"runtimeId",
		"requestIds",
		"boundaryIds",
		"auditKind",
		"auditStatus",
		"reviewer",
		"evidence",
		"tags",
		"metadata",
	},
}

local EXPECTED_ENUMS = {
	RuntimeKind = {
		"MetadataRuntime",
		"RequestRuntime",
		"BoundaryRuntime",
		"AuditRuntime",
		"FuturePipelineRuntime",
	},
	RuntimeStatus = {
		"Declared",
		"Ready",
		"Deferred",
		"Warning",
		"Blocked",
	},
	RequestKind = {
		"RuntimeMetadataRequest",
		"ReadinessMetadataRequest",
		"BoundaryMetadataRequest",
		"AuditMetadataRequest",
		"FuturePipelineRequest",
	},
	RequestStatus = {
		"Declared",
		"Validated",
		"Deferred",
		"Warning",
		"Blocked",
	},
	BoundaryKind = {
		"NoAssetLoading",
		"NoAssetStreaming",
		"NoAssetSpawning",
		"NoAssetApplication",
		"NoAssetPlayback",
		"NoPresentation",
		"NoSave",
		"NoGameplay",
		"NoNetworking",
		"NoWorldMutation",
		"NoPersistence",
		"NoRouting",
		"NoDispatch",
		"NoQueueing",
		"NoScheduling",
		"NoOrchestration",
	},
	BoundaryStatus = {
		"Declared",
		"Satisfied",
		"Deferred",
		"Warning",
		"Blocked",
	},
	AuditKind = {
		"RuntimeAudit",
		"RequestAudit",
		"BoundaryAudit",
		"ProductionAudit",
	},
	AuditStatus = {
		"Passed",
		"Failed",
		"Warning",
		"Deferred",
		"Blocked",
	},
	IntegrationKind = {
		"AuthorizationRuntimeCompatibility",
		"AuthorizationProviderCompatibility",
		"AuthorizationSnapshotCompatibility",
		"ExecutionReadinessCompatibility",
		"ExecutionRuntimeCompatibility",
		"ExecutionProviderCompatibility",
		"ExecutionSnapshotCompatibility",
		"ExecutionCoordinatorCompatibility",
		"BootstrapCompatibility",
		"EngineGovernanceCompatibility",
		"DocumentationCompatibility",
		"SchemaCompatibility",
		"EnumCompatibility",
		"ReferenceIntegrityCompatibility",
		"SerializationCompatibility",
		"DiagnosticsCompatibility",
		"SnapshotIsolationCompatibility",
		"RuntimeLimitCompatibility",
		"SignalBoundaryCompatibility",
		"CoordinatorBoundaryCompatibility",
		"LifecycleCompatibility",
		"FutureAdapterSeparation",
		"FutureAssetOperationSeparation",
		"FutureGameplaySeparation",
	},
	IntegrationStatus = {
		"Declared",
		"Compatible",
		"IntegrationReady",
		"BoundaryReady",
		"ObservationOnly",
		"Deferred",
		"Warning",
		"Blocked",
	},
	AdapterBoundaryKind = {
		"NoExecutionAdapter",
		"NoAssetLoaderAdapter",
		"NoAssetSpawnAdapter",
		"NoAssetApplicationAdapter",
		"NoAssetPlaybackAdapter",
		"NoRoutingAdapter",
		"NoDispatchAdapter",
		"NoQueueAdapter",
		"NoSchedulerAdapter",
		"NoOrchestrationAdapter",
		"FutureAdapterSeparate",
	},
	AssetOperationBoundaryKind = {
		"NoAssetLoading",
		"NoAssetPreloading",
		"NoAssetStreaming",
		"NoAssetSpawning",
		"NoAssetCloning",
		"NoAssetInsertion",
		"NoAssetApplication",
		"NoAssetDisplay",
		"NoAssetPlayback",
		"NoAnimationPlayback",
		"NoAudioPlayback",
		"NoWorldMutation",
		"NoStorageMutation",
		"NoNetworkOwnership",
		"NoPhysicsExecution",
		"NoGameplayExecution",
		"FutureAssetOperationsSeparate",
		"FutureGameplaySeparate",
	},
	AdapterReadinessKind = {
		"ExecutionRuntimeCompatibility",
		"ExecutionProviderCompatibility",
		"ExecutionSnapshotCompatibility",
		"ExecutionCoordinatorCompatibility",
		"AdapterIdentityReadiness",
		"AdapterProviderReadiness",
		"AdapterSnapshotReadiness",
		"AdapterCoordinatorReadiness",
		"AdapterSchemaReadiness",
		"AdapterValidationReadiness",
		"AdapterSerializationReadiness",
		"AdapterDiagnosticsReadiness",
		"AdapterSnapshotIsolationReadiness",
		"AdapterLifecycleReadiness",
		"AdapterRuntimeLimitReadiness",
		"BootstrapReadiness",
		"EngineGovernanceReadiness",
		"DocumentationReadiness",
		"ServerAuthorityReadiness",
		"ClientAuthoritySeparation",
		"CallbackSeparation",
		"ListenerSeparation",
		"ServiceReferenceSeparation",
		"ModuleReferenceSeparation",
		"RuntimeHandleSeparation",
		"AssetHandleSeparation",
		"RoutingSeparation",
		"DispatchSeparation",
		"QueueSeparation",
		"SchedulerSeparation",
		"OrchestrationSeparation",
		"AssetLoadingSeparation",
		"AssetSpawningSeparation",
		"AssetApplicationSeparation",
		"AssetDisplaySeparation",
		"AssetPlaybackSeparation",
		"GameplaySeparation",
		"FutureAdapterRuntimeReadiness",
	},
	AdapterReadinessStatus = {
		"Declared",
		"Compatible",
		"ReadinessConfirmed",
		"BoundaryConfirmed",
		"ObservationOnly",
		"Deferred",
		"Warning",
		"Blocked",
	},
	FutureAdapterKind = {
		"NoAdapterKind",
		"AssetAcquisitionAdapter",
		"AssetFormationAdapter",
		"AssetApplicationAdapter",
		"AssetPresentationAdapter",
		"AudioAdapter",
		"AnimationAdapter",
		"WorldMutationAdapter",
		"OperationBoundaryAdapter",
		"GovernanceAdapter",
	},
	AdapterAuthorityKind = {
		"NoAuthority",
		"MetadataOnly",
		"ServerAuthoritativeFuture",
		"NoClientAuthority",
		"NoDirectExecution",
		"FutureGovernedAuthorityRequired",
		"FutureAuthorizationRequired",
		"FutureRuntimePermitRequired",
	},
	AdapterReadinessBoundaryKind = {
		"NoLiveAdapter",
		"NoAdapterModule",
		"NoAdapterCallback",
		"NoAdapterListener",
		"NoAdapterService",
		"NoAdapterRegistry",
		"NoAdapterActivation",
		"NoAdapterResolution",
		"NoAdapterDispatch",
		"NoAdapterQueue",
		"FutureAdapterSeparate",
	},
	AdapterAssetOperationBoundaryKind = {
		"NoAssetLoading",
		"NoAssetPreloading",
		"NoAssetStreaming",
		"NoAssetSpawning",
		"NoAssetCloning",
		"NoAssetInsertion",
		"NoAssetApplication",
		"NoAssetDisplay",
		"NoAssetPlayback",
		"NoAnimationPlayback",
		"NoAudioPlayback",
		"NoModelCreation",
		"NoInterfaceSurface",
		"NoVisualEffects",
		"NoWorldMutation",
		"NoStorageMutation",
		"NoNetworkOwnership",
		"NoPhysicsExecution",
		"NoGameplayExecution",
		"FutureAssetOperationsSeparate",
	},
	AdapterLifecycleBoundaryKind = {
		"NoAdapterInitialization",
		"NoAdapterStart",
		"NoAdapterActivation",
		"NoAdapterExecution",
		"NoAdapterShutdownOwnership",
		"NoAdapterRecovery",
		"FutureLifecycleSeparate",
	},
}

local EXPECTED_LIMITS = {
	MaxRuntimes = 160,
	MaxRequests = 480,
	MaxBoundaries = 320,
	MaxAudits = 240,
	MaxValidationFailures = 220,
	MaxSnapshotHistory = 60,
	MaxPayloadDepth = 8,
	MaxPayloadNodes = 520,
	MaxStringLength = 280,
	MaxTags = 32,
	MaxEvidence = 56,
	MaxChildReferences = 220,
	MaxSummaryLength = 180,
}

local EXPECTED_POSTURE_KEYS = {
	"assetExecutionRuntimePosture",
	"assetExecutionRequestPosture",
	"assetExecutionBoundaryPosture",
	"assetExecutionAuditPosture",
	"assetExecutionIntegrationReadinessPosture",
	"assetExecutionCompatibilityPosture",
	"assetExecutionIntegrationHardeningPosture",
	"assetExecutionDeclarationExactnessPosture",
	"assetExecutionDeclarationOrderingPosture",
	"assetExecutionCompatibilityIdentityPosture",
	"assetExecutionOrderTablePosture",
	"assetExecutionMetadataExactnessPosture",
	"assetExecutionEvidenceExactnessPosture",
	"assetExecutionTagExactnessPosture",
	"assetExecutionAdapterContaminationPosture",
	"assetExecutionOperationContaminationPosture",
	"assetExecutionIntegrationLimitIsolationPosture",
	"assetExecutionIntegrationDocumentationConsistencyPosture",
	"assetExecutionAdapterReadinessPosture",
	"assetExecutionAdapterCompatibilityPosture",
	"assetExecutionAdapterIdentityPosture",
	"assetExecutionAdapterAuthorityPosture",
	"assetExecutionAdapterBoundaryPosture",
	"assetExecutionAdapterLifecyclePosture",
	"assetExecutionAdapterSerializationPosture",
	"assetExecutionAdapterIsolationPosture",
	"assetExecutionAdapterLimitPosture",
	"assetExecutionAdapterDocumentationPosture",
	"assetExecutionNoLiveAdapterPosture",
	"assetExecutionNoAssetOperationPosture",
	"assetExecutionAdapterHardeningPosture",
	"assetExecutionAdapterIdentityHardeningPosture",
	"assetExecutionAdapterBoundaryHardeningPosture",
	"assetExecutionAdapterDocumentationHardeningPosture",
	"assetExecutionAdapterSerializationHardeningPosture",
	"assetExecutionAdapterValidationHardeningPosture",
	"assetExecutionAdapterIsolationHardeningPosture",
	"assetExecutionAdapterLimitHardeningPosture",
	"assetExecutionAdapterGovernanceHardeningPosture",
	"assetExecutionAdapterBootstrapHardeningPosture",
	"assetExecutionSchemaPosture",
	"assetExecutionEnumPosture",
	"assetExecutionReferencePosture",
	"assetExecutionArrayPosture",
	"assetExecutionLimitPosture",
	"assetExecutionSignalPosture",
	"assetExecutionCoordinatorBoundaryPosture",
	"assetExecutionFutureAdapterSeparationPosture",
	"assetExecutionFutureAssetOperationSeparationPosture",
	"assetExecutionFutureGameplaySeparationPosture",
	"assetExecutionIsolationPosture",
	"assetExecutionValidationPosture",
	"assetExecutionLifecyclePosture",
	"assetExecutionNoAuthorityPosture",
	"noExecution",
	"noAssetLoading",
	"noGameplay",
	"noPresentation",
	"noSave",
	"noNetworking",
	"noAnalytics",
	"noTelemetry",
}

local EXPECTED_COORDINATOR_API = {
	"initialize",
	"start",
	"shutdown",
	"registerExecutionRuntime",
	"registerExecutionRequest",
	"registerExecutionBoundary",
	"registerExecutionAudit",
	"inspect",
	"getSnapshot",
	"validate",
	"runSelfChecks",
}

local EXPECTED_SIGNAL_NAMES = {
	Initialized = "AssetExecutionRuntime.Initialized",
	Started = "AssetExecutionRuntime.Started",
	Shutdown = "AssetExecutionRuntime.Shutdown",
	ValidationFailed = "AssetExecutionRuntime.ValidationFailed",
}

local EXPECTED_INTEGRATION_DECLARATION_FIELDS = {
	"integrationId",
	"compatibilityId",
	"integrationDeclarationId",
	"integrationKind",
	"integrationStatus",
	"runtimeName",
	"providerName",
	"snapshotProviderName",
	"coordinatorName",
	"diagnosticsProviderName",
	"bootstrapDependencyName",
	"engineGovernanceSnapshotProviderName",
	"documentationReference",
	"authorizationRuntimeName",
	"authorizationProviderName",
	"authorizationSnapshotProviderName",
	"readinessEvidenceKind",
	"executionRuntimeName",
	"executionProviderName",
	"executionSnapshotProviderName",
	"executionCoordinatorName",
	"adapterBoundaryKind",
	"assetOperationBoundaryKind",
	"required",
	"evidence",
	"tags",
	"metadata",
}

local EXPECTED_ADAPTER_READINESS_DECLARATION_FIELDS = {
	"readinessId",
	"compatibilityId",
	"adapterReadinessDeclarationId",
	"readinessKind",
	"readinessStatus",
	"runtimeName",
	"providerName",
	"snapshotProviderName",
	"coordinatorName",
	"diagnosticsProviderName",
	"bootstrapDependencyName",
	"engineGovernanceSnapshotProviderName",
	"documentationReference",
	"executionRuntimeName",
	"executionProviderName",
	"executionSnapshotProviderName",
	"executionCoordinatorName",
	"futureAdapterRuntimeName",
	"futureAdapterProviderName",
	"futureAdapterSnapshotProviderName",
	"futureAdapterCoordinatorName",
	"adapterKind",
	"adapterAuthorityKind",
	"adapterBoundaryKind",
	"assetOperationBoundaryKind",
	"lifecycleBoundaryKind",
	"required",
	"evidence",
	"tags",
	"metadata",
}

local EXPECTED_INTEGRATION_ROWS = {
	{
		"01",
		"authorization.runtime",
		"AuthorizationRuntimeCompatibility",
		"Compatible",
		"ASSET_EXECUTION_AUTHORIZATION_RUNTIME.md",
		"AuthorizationRuntimeEvidence",
		"NoExecutionAdapter",
		"NoAssetLoading",
	},
	{
		"02",
		"authorization.provider",
		"AuthorizationProviderCompatibility",
		"Compatible",
		"ASSET_EXECUTION_AUTHORIZATION_RUNTIME.md",
		"AuthorizationProviderEvidence",
		"NoAssetLoaderAdapter",
		"NoAssetPreloading",
	},
	{
		"03",
		"authorization.snapshot",
		"AuthorizationSnapshotCompatibility",
		"Compatible",
		"ASSET_EXECUTION_AUTHORIZATION_DIAGNOSTICS.md",
		"AuthorizationSnapshotEvidence",
		"NoAssetSpawnAdapter",
		"NoAssetStreaming",
	},
	{
		"04",
		"execution.readiness",
		"ExecutionReadinessCompatibility",
		"Compatible",
		"ASSET_EXECUTION_AUTHORIZATION_EXECUTION_READINESS.md",
		"AssetExecutionReadinessEvidence",
		"NoAssetApplicationAdapter",
		"NoAssetSpawning",
	},
	{
		"05",
		"execution.runtime",
		"ExecutionRuntimeCompatibility",
		"IntegrationReady",
		"ASSET_EXECUTION_RUNTIME.md",
		"ExecutionRuntimeIdentityEvidence",
		"NoAssetPlaybackAdapter",
		"NoAssetCloning",
	},
	{
		"06",
		"execution.provider",
		"ExecutionProviderCompatibility",
		"IntegrationReady",
		"ASSET_EXECUTION_RUNTIME.md",
		"ExecutionProviderEvidence",
		"NoRoutingAdapter",
		"NoAssetInsertion",
	},
	{
		"07",
		"execution.snapshot",
		"ExecutionSnapshotCompatibility",
		"IntegrationReady",
		"ASSET_EXECUTION_DIAGNOSTICS.md",
		"ExecutionSnapshotEvidence",
		"NoDispatchAdapter",
		"NoAssetApplication",
	},
	{
		"08",
		"execution.coordinator",
		"ExecutionCoordinatorCompatibility",
		"IntegrationReady",
		"ASSET_EXECUTION_RUNTIME.md",
		"ExecutionCoordinatorEvidence",
		"NoQueueAdapter",
		"NoAssetDisplay",
	},
	{
		"09",
		"bootstrap",
		"BootstrapCompatibility",
		"Compatible",
		"ASSET_EXECUTION_RUNTIME.md",
		"BootstrapEvidence",
		"NoSchedulerAdapter",
		"NoAssetPlayback",
	},
	{
		"10",
		"engine.governance",
		"EngineGovernanceCompatibility",
		"Compatible",
		"ASSET_EXECUTION_PRODUCTION_REVIEW.md",
		"EngineGovernanceEvidence",
		"NoOrchestrationAdapter",
		"NoAnimationPlayback",
	},
	{
		"11",
		"documentation",
		"DocumentationCompatibility",
		"Compatible",
		"ASSET_EXECUTION_RUNTIME_INTEGRATION_READINESS.md",
		"DocumentationEvidence",
		"FutureAdapterSeparate",
		"NoAudioPlayback",
	},
	{
		"12",
		"schema",
		"SchemaCompatibility",
		"Compatible",
		"ASSET_EXECUTION_VALIDATION.md",
		"SchemaEvidence",
		"NoExecutionAdapter",
		"NoWorldMutation",
	},
	{
		"13",
		"enum",
		"EnumCompatibility",
		"Compatible",
		"ASSET_EXECUTION_VALIDATION.md",
		"EnumEvidence",
		"NoAssetLoaderAdapter",
		"NoStorageMutation",
	},
	{
		"14",
		"reference.integrity",
		"ReferenceIntegrityCompatibility",
		"Compatible",
		"ASSET_EXECUTION_AUDIT.md",
		"ReferenceIntegrityEvidence",
		"NoAssetSpawnAdapter",
		"NoNetworkOwnership",
	},
	{
		"15",
		"serialization",
		"SerializationCompatibility",
		"ObservationOnly",
		"ASSET_EXECUTION_SERIALIZATION.md",
		"SerializationEvidence",
		"NoAssetApplicationAdapter",
		"NoPhysicsExecution",
	},
	{
		"16",
		"diagnostics",
		"DiagnosticsCompatibility",
		"ObservationOnly",
		"ASSET_EXECUTION_DIAGNOSTICS.md",
		"DiagnosticsEvidence",
		"NoAssetPlaybackAdapter",
		"NoGameplayExecution",
	},
	{
		"17",
		"snapshot.isolation",
		"SnapshotIsolationCompatibility",
		"ObservationOnly",
		"ASSET_EXECUTION_DIAGNOSTICS.md",
		"SnapshotIsolationEvidence",
		"NoRoutingAdapter",
		"FutureAssetOperationsSeparate",
	},
	{
		"18",
		"runtime.limit",
		"RuntimeLimitCompatibility",
		"ObservationOnly",
		"ASSET_EXECUTION_RUNTIME_LIMITS.md",
		"RuntimeLimitEvidence",
		"NoDispatchAdapter",
		"FutureGameplaySeparate",
	},
	{
		"19",
		"signal.boundary",
		"SignalBoundaryCompatibility",
		"BoundaryReady",
		"ASSET_EXECUTION_SELF_CHECKS.md",
		"SignalBoundaryEvidence",
		"NoQueueAdapter",
		"NoAssetLoading",
	},
	{
		"20",
		"coordinator.boundary",
		"CoordinatorBoundaryCompatibility",
		"BoundaryReady",
		"ASSET_EXECUTION_SELF_CHECKS.md",
		"CoordinatorBoundaryEvidence",
		"NoSchedulerAdapter",
		"NoAssetSpawning",
	},
	{
		"21",
		"lifecycle",
		"LifecycleCompatibility",
		"ObservationOnly",
		"ASSET_EXECUTION_SELF_CHECKS.md",
		"LifecycleEvidence",
		"NoOrchestrationAdapter",
		"NoAssetPlayback",
	},
	{
		"22",
		"future.adapter",
		"FutureAdapterSeparation",
		"BoundaryReady",
		"ASSET_EXECUTION_PRODUCTION_REVIEW.md",
		"FutureAdapterSeparationEvidence",
		"FutureAdapterSeparate",
		"FutureAssetOperationsSeparate",
	},
	{
		"23",
		"future.asset.operation",
		"FutureAssetOperationSeparation",
		"BoundaryReady",
		"ASSET_EXECUTION_PRODUCTION_REVIEW.md",
		"FutureAssetOperationSeparationEvidence",
		"FutureAdapterSeparate",
		"FutureAssetOperationsSeparate",
	},
	{
		"24",
		"future.gameplay",
		"FutureGameplaySeparation",
		"BoundaryReady",
		"ASSET_EXECUTION_PRODUCTION_REVIEW.md",
		"FutureGameplaySeparationEvidence",
		"FutureAdapterSeparate",
		"FutureGameplaySeparate",
	},
}

local EXPECTED_ADAPTER_READINESS_ROWS = {
	{
		"01",
		"execution.runtime",
		"ExecutionRuntimeCompatibility",
		"Compatible",
		"ASSET_EXECUTION_RUNTIME.md",
		"GovernanceAdapter",
		"MetadataOnly",
		"NoLiveAdapter",
		"NoAssetLoading",
		"NoAdapterInitialization",
	},
	{
		"02",
		"execution.provider",
		"ExecutionProviderCompatibility",
		"Compatible",
		"ASSET_EXECUTION_RUNTIME.md",
		"GovernanceAdapter",
		"MetadataOnly",
		"NoAdapterModule",
		"NoAssetPreloading",
		"NoAdapterStart",
	},
	{
		"03",
		"execution.snapshot",
		"ExecutionSnapshotCompatibility",
		"Compatible",
		"ASSET_EXECUTION_DIAGNOSTICS.md",
		"GovernanceAdapter",
		"MetadataOnly",
		"NoAdapterCallback",
		"NoAssetStreaming",
		"NoAdapterActivation",
	},
	{
		"04",
		"execution.coordinator",
		"ExecutionCoordinatorCompatibility",
		"Compatible",
		"ASSET_EXECUTION_RUNTIME.md",
		"GovernanceAdapter",
		"MetadataOnly",
		"NoAdapterListener",
		"NoAssetSpawning",
		"NoAdapterExecution",
	},
	{
		"05",
		"identity",
		"AdapterIdentityReadiness",
		"ReadinessConfirmed",
		"ASSET_EXECUTION_ADAPTER_READINESS.md",
		"NoAdapterKind",
		"NoAuthority",
		"NoAdapterService",
		"NoAssetCloning",
		"NoAdapterShutdownOwnership",
	},
	{
		"06",
		"provider",
		"AdapterProviderReadiness",
		"Deferred",
		"ASSET_EXECUTION_ADAPTER_READINESS.md",
		"NoAdapterKind",
		"NoAuthority",
		"NoAdapterRegistry",
		"NoAssetInsertion",
		"NoAdapterRecovery",
	},
	{
		"07",
		"snapshot",
		"AdapterSnapshotReadiness",
		"Deferred",
		"ASSET_EXECUTION_ADAPTER_READINESS_DIAGNOSTICS.md",
		"NoAdapterKind",
		"NoAuthority",
		"NoAdapterActivation",
		"NoAssetApplication",
		"FutureLifecycleSeparate",
	},
	{
		"08",
		"coordinator",
		"AdapterCoordinatorReadiness",
		"Deferred",
		"ASSET_EXECUTION_ADAPTER_READINESS.md",
		"NoAdapterKind",
		"NoAuthority",
		"NoAdapterResolution",
		"NoAssetDisplay",
		"NoAdapterInitialization",
	},
	{
		"09",
		"schema",
		"AdapterSchemaReadiness",
		"ReadinessConfirmed",
		"ASSET_EXECUTION_ADAPTER_READINESS_VALIDATION.md",
		"GovernanceAdapter",
		"MetadataOnly",
		"NoAdapterDispatch",
		"NoAssetPlayback",
		"NoAdapterStart",
	},
	{
		"10",
		"validation",
		"AdapterValidationReadiness",
		"ReadinessConfirmed",
		"ASSET_EXECUTION_ADAPTER_READINESS_VALIDATION.md",
		"GovernanceAdapter",
		"MetadataOnly",
		"NoAdapterQueue",
		"NoAnimationPlayback",
		"NoAdapterActivation",
	},
	{
		"11",
		"serialization",
		"AdapterSerializationReadiness",
		"ReadinessConfirmed",
		"ASSET_EXECUTION_SERIALIZATION.md",
		"GovernanceAdapter",
		"MetadataOnly",
		"FutureAdapterSeparate",
		"NoAudioPlayback",
		"NoAdapterExecution",
	},
	{
		"12",
		"diagnostics",
		"AdapterDiagnosticsReadiness",
		"ObservationOnly",
		"ASSET_EXECUTION_ADAPTER_READINESS_DIAGNOSTICS.md",
		"GovernanceAdapter",
		"MetadataOnly",
		"NoLiveAdapter",
		"NoModelCreation",
		"NoAdapterShutdownOwnership",
	},
	{
		"13",
		"snapshot.isolation",
		"AdapterSnapshotIsolationReadiness",
		"ObservationOnly",
		"ASSET_EXECUTION_ADAPTER_READINESS_DIAGNOSTICS.md",
		"GovernanceAdapter",
		"MetadataOnly",
		"NoAdapterModule",
		"NoInterfaceSurface",
		"NoAdapterRecovery",
	},
	{
		"14",
		"lifecycle",
		"AdapterLifecycleReadiness",
		"BoundaryConfirmed",
		"ASSET_EXECUTION_ADAPTER_READINESS.md",
		"GovernanceAdapter",
		"NoDirectExecution",
		"NoAdapterCallback",
		"NoVisualEffects",
		"FutureLifecycleSeparate",
	},
	{
		"15",
		"runtime.limit",
		"AdapterRuntimeLimitReadiness",
		"ReadinessConfirmed",
		"ASSET_EXECUTION_RUNTIME_LIMITS.md",
		"GovernanceAdapter",
		"MetadataOnly",
		"NoAdapterListener",
		"NoWorldMutation",
		"NoAdapterInitialization",
	},
	{
		"16",
		"bootstrap",
		"BootstrapReadiness",
		"Compatible",
		"ASSET_EXECUTION_RUNTIME.md",
		"GovernanceAdapter",
		"MetadataOnly",
		"NoAdapterService",
		"NoStorageMutation",
		"NoAdapterStart",
	},
	{
		"17",
		"engine.governance",
		"EngineGovernanceReadiness",
		"Compatible",
		"ASSET_EXECUTION_PRODUCTION_REVIEW.md",
		"GovernanceAdapter",
		"MetadataOnly",
		"NoAdapterRegistry",
		"NoNetworkOwnership",
		"NoAdapterActivation",
	},
	{
		"18",
		"documentation",
		"DocumentationReadiness",
		"ReadinessConfirmed",
		"ASSET_EXECUTION_ADAPTER_READINESS.md",
		"GovernanceAdapter",
		"MetadataOnly",
		"NoAdapterActivation",
		"NoPhysicsExecution",
		"NoAdapterExecution",
	},
	{
		"19",
		"server.authority",
		"ServerAuthorityReadiness",
		"BoundaryConfirmed",
		"ASSET_EXECUTION_ADAPTER_READINESS_PRODUCTION_REVIEW.md",
		"GovernanceAdapter",
		"ServerAuthoritativeFuture",
		"NoAdapterResolution",
		"NoGameplayExecution",
		"NoAdapterShutdownOwnership",
	},
	{
		"20",
		"client.authority",
		"ClientAuthoritySeparation",
		"BoundaryConfirmed",
		"ASSET_EXECUTION_ADAPTER_READINESS_PRODUCTION_REVIEW.md",
		"GovernanceAdapter",
		"NoClientAuthority",
		"NoAdapterDispatch",
		"FutureAssetOperationsSeparate",
		"NoAdapterRecovery",
	},
	{
		"21",
		"callback.separation",
		"CallbackSeparation",
		"BoundaryConfirmed",
		"ASSET_EXECUTION_ADAPTER_READINESS_SELF_CHECKS.md",
		"GovernanceAdapter",
		"NoDirectExecution",
		"NoAdapterCallback",
		"NoAssetLoading",
		"FutureLifecycleSeparate",
	},
	{
		"22",
		"listener.separation",
		"ListenerSeparation",
		"BoundaryConfirmed",
		"ASSET_EXECUTION_ADAPTER_READINESS_SELF_CHECKS.md",
		"GovernanceAdapter",
		"NoDirectExecution",
		"NoAdapterListener",
		"NoAssetPreloading",
		"NoAdapterInitialization",
	},
	{
		"23",
		"service.reference",
		"ServiceReferenceSeparation",
		"BoundaryConfirmed",
		"ASSET_EXECUTION_ADAPTER_READINESS_SELF_CHECKS.md",
		"GovernanceAdapter",
		"NoDirectExecution",
		"NoAdapterService",
		"NoAssetStreaming",
		"NoAdapterStart",
	},
	{
		"24",
		"module.reference",
		"ModuleReferenceSeparation",
		"BoundaryConfirmed",
		"ASSET_EXECUTION_ADAPTER_READINESS_SELF_CHECKS.md",
		"GovernanceAdapter",
		"NoDirectExecution",
		"NoAdapterModule",
		"NoAssetSpawning",
		"NoAdapterActivation",
	},
	{
		"25",
		"runtime.handle",
		"RuntimeHandleSeparation",
		"BoundaryConfirmed",
		"ASSET_EXECUTION_ADAPTER_READINESS_SELF_CHECKS.md",
		"GovernanceAdapter",
		"FutureGovernedAuthorityRequired",
		"NoLiveAdapter",
		"NoAssetCloning",
		"NoAdapterExecution",
	},
	{
		"26",
		"asset.handle",
		"AssetHandleSeparation",
		"BoundaryConfirmed",
		"ASSET_EXECUTION_ADAPTER_READINESS_SELF_CHECKS.md",
		"GovernanceAdapter",
		"FutureAuthorizationRequired",
		"NoAdapterRegistry",
		"NoAssetInsertion",
		"NoAdapterShutdownOwnership",
	},
	{
		"27",
		"routing",
		"RoutingSeparation",
		"BoundaryConfirmed",
		"ASSET_EXECUTION_ADAPTER_READINESS_PRODUCTION_REVIEW.md",
		"GovernanceAdapter",
		"NoDirectExecution",
		"NoAdapterResolution",
		"NoAssetApplication",
		"NoAdapterRecovery",
	},
	{
		"28",
		"dispatch",
		"DispatchSeparation",
		"BoundaryConfirmed",
		"ASSET_EXECUTION_ADAPTER_READINESS_PRODUCTION_REVIEW.md",
		"GovernanceAdapter",
		"NoDirectExecution",
		"NoAdapterDispatch",
		"NoAssetDisplay",
		"FutureLifecycleSeparate",
	},
	{
		"29",
		"queue",
		"QueueSeparation",
		"BoundaryConfirmed",
		"ASSET_EXECUTION_ADAPTER_READINESS_PRODUCTION_REVIEW.md",
		"GovernanceAdapter",
		"NoDirectExecution",
		"NoAdapterQueue",
		"NoAssetPlayback",
		"NoAdapterInitialization",
	},
	{
		"30",
		"scheduler",
		"SchedulerSeparation",
		"BoundaryConfirmed",
		"ASSET_EXECUTION_ADAPTER_READINESS_PRODUCTION_REVIEW.md",
		"GovernanceAdapter",
		"NoDirectExecution",
		"FutureAdapterSeparate",
		"NoAnimationPlayback",
		"NoAdapterStart",
	},
	{
		"31",
		"orchestration",
		"OrchestrationSeparation",
		"BoundaryConfirmed",
		"ASSET_EXECUTION_ADAPTER_READINESS_PRODUCTION_REVIEW.md",
		"GovernanceAdapter",
		"NoDirectExecution",
		"NoLiveAdapter",
		"NoAudioPlayback",
		"NoAdapterActivation",
	},
	{
		"32",
		"asset.loading",
		"AssetLoadingSeparation",
		"BoundaryConfirmed",
		"ASSET_EXECUTION_ADAPTER_READINESS_PRODUCTION_REVIEW.md",
		"AssetAcquisitionAdapter",
		"FutureRuntimePermitRequired",
		"NoAdapterModule",
		"NoAssetLoading",
		"NoAdapterExecution",
	},
	{
		"33",
		"asset.spawning",
		"AssetSpawningSeparation",
		"BoundaryConfirmed",
		"ASSET_EXECUTION_ADAPTER_READINESS_PRODUCTION_REVIEW.md",
		"AssetFormationAdapter",
		"FutureRuntimePermitRequired",
		"NoAdapterCallback",
		"NoAssetSpawning",
		"NoAdapterShutdownOwnership",
	},
	{
		"34",
		"asset.application",
		"AssetApplicationSeparation",
		"BoundaryConfirmed",
		"ASSET_EXECUTION_ADAPTER_READINESS_PRODUCTION_REVIEW.md",
		"AssetApplicationAdapter",
		"FutureRuntimePermitRequired",
		"NoAdapterListener",
		"NoAssetApplication",
		"NoAdapterRecovery",
	},
	{
		"35",
		"asset.display",
		"AssetDisplaySeparation",
		"BoundaryConfirmed",
		"ASSET_EXECUTION_ADAPTER_READINESS_PRODUCTION_REVIEW.md",
		"AssetPresentationAdapter",
		"FutureRuntimePermitRequired",
		"NoAdapterService",
		"NoAssetDisplay",
		"FutureLifecycleSeparate",
	},
	{
		"36",
		"asset.playback",
		"AssetPlaybackSeparation",
		"BoundaryConfirmed",
		"ASSET_EXECUTION_ADAPTER_READINESS_PRODUCTION_REVIEW.md",
		"AudioAdapter",
		"FutureRuntimePermitRequired",
		"NoAdapterRegistry",
		"NoAssetPlayback",
		"NoAdapterInitialization",
	},
	{
		"37",
		"gameplay",
		"GameplaySeparation",
		"BoundaryConfirmed",
		"ASSET_EXECUTION_ADAPTER_READINESS_PRODUCTION_REVIEW.md",
		"OperationBoundaryAdapter",
		"NoDirectExecution",
		"NoAdapterActivation",
		"NoGameplayExecution",
		"NoAdapterStart",
	},
	{
		"38",
		"future.adapter.runtime",
		"FutureAdapterRuntimeReadiness",
		"Deferred",
		"ASSET_EXECUTION_ADAPTER_READINESS.md",
		"NoAdapterKind",
		"FutureGovernedAuthorityRequired",
		"FutureAdapterSeparate",
		"FutureAssetOperationsSeparate",
		"FutureLifecycleSeparate",
	},
}

local fieldLookup: { [string]: { [string]: boolean } } = {}
for schemaName, fields in pairs(Types.SchemaFields) do
	local lookup = {}
	for _, field in ipairs(fields) do
		lookup[field] = true
	end
	fieldLookup[schemaName] = lookup
end

local function validId(value: any): boolean
	return type(value) == "string"
		and value ~= ""
		and #value <= 150
		and string.match(value, "^[%w%._%-:]+$") ~= nil
end

local function validateArrayIds(values: any, limit: number, label: string): (boolean, string?)
	if values == nil then
		return true, nil
	end
	if type(values) ~= "table" then
		return false, label .. " must be a table"
	end
	local count = 0
	for key in pairs(values) do
		if type(key) ~= "number" or key ~= math.floor(key) or key < 1 then
			return false, label .. " must be an ordered array"
		end
		count += 1
	end
	if count ~= #values then
		return false, label .. " must not be sparse"
	end
	if count > limit then
		return false, label .. " exceeds limit"
	end
	local seen: { [string]: boolean } = {}
	local previous = ""
	for _, value in ipairs(values) do
		if not validId(value) then
			return false, label .. " contains invalid id"
		end
		if seen[value] then
			return false, label .. " contains duplicate id"
		end
		if previous ~= "" and value < previous then
			return false, label .. " must be deterministic ascending order"
		end
		previous = value
		seen[value] = true
	end
	return true, nil
end

local function validateMetadata(metadata: any, label: string): (boolean, string?)
	if type(metadata) ~= "table" then
		return false, label .. " metadata is required"
	end
	for key in pairs(metadata) do
		if type(key) ~= "string" or not validId(key) then
			return false, label .. " metadata key is invalid"
		end
	end
	return true, nil
end

local function validateExactArray(
	values: { string },
	expected: { string },
	label: string
): (boolean, string?)
	if #values ~= #expected then
		return false, label .. " count drift"
	end
	for index, value in ipairs(values) do
		if value ~= expected[index] then
			return false, label .. " ordering drift"
		end
	end
	return true, nil
end

local function validateExactBoolMap(
	values: { [string]: boolean },
	expected: { string },
	label: string
): (boolean, string?)
	local count = 0
	for key, value in pairs(values) do
		count += 1
		if value ~= true then
			return false, label .. " value drift"
		end
		local found = false
		for _, expectedKey in ipairs(expected) do
			if key == expectedKey then
				found = true
				break
			end
		end
		if not found then
			return false, label .. " unsupported value"
		end
	end
	if count ~= #expected then
		return false, label .. " count drift"
	end
	for _, expectedKey in ipairs(expected) do
		if values[expectedKey] ~= true then
			return false, label .. " missing value"
		end
	end
	return true, nil
end

local function validateExactNumberMap(
	values: { [string]: number },
	expected: { [string]: number },
	label: string
): (boolean, string?)
	local count = 0
	for key, value in pairs(values) do
		count += 1
		if expected[key] == nil then
			return false, label .. " unsupported key"
		end
		if value ~= expected[key] then
			return false, label .. " value drift"
		end
	end
	local expectedCount = 0
	for key in pairs(expected) do
		expectedCount += 1
		if values[key] ~= expected[key] then
			return false, label .. " missing value"
		end
	end
	if count ~= expectedCount then
		return false, label .. " count drift"
	end
	return true, nil
end

local function validateExactStringMap(
	values: { [string]: string },
	expected: { [string]: string },
	label: string
): (boolean, string?)
	local count = 0
	for key, value in pairs(values) do
		count += 1
		if expected[key] == nil then
			return false, label .. " unsupported key"
		end
		if value ~= expected[key] then
			return false, label .. " value drift"
		end
	end
	local expectedCount = 0
	for key in pairs(expected) do
		expectedCount += 1
		if values[key] ~= expected[key] then
			return false, label .. " missing value"
		end
	end
	if count ~= expectedCount then
		return false, label .. " count drift"
	end
	return true, nil
end

local function orderNameForField(fieldName: string): string
	return string.upper(string.sub(fieldName, 1, 1)) .. string.sub(fieldName, 2) .. "Order"
end

local function validateExactDeclarationArray(
	values: any,
	expected: { string },
	label: string
): (boolean, string?)
	if type(values) ~= "table" then
		return false, label .. " must be a table"
	end
	for key in pairs(values) do
		if type(key) ~= "number" or key ~= math.floor(key) or key < 1 then
			return false, label .. " must be an ordered array"
		end
	end
	return validateExactArray(values, expected, label)
end

local function validateEvidence(values: any): (boolean, string?)
	if values == nil then
		return false, "evidence is required"
	end
	return validateArrayIds(values, Types.Limits.MaxEvidence, "evidence")
end

local function validateTags(tags: any): (boolean, string?)
	if tags == nil then
		return false, "tags are required"
	end
	return validateArrayIds(tags, Types.Limits.MaxTags, "tags")
end

local function buildExpectedIntegrationContracts()
	local expectedDeclarations = {}
	local expectedOrder = {}
	for _, fieldName in ipairs(EXPECTED_INTEGRATION_DECLARATION_FIELDS) do
		if fieldName ~= "evidence" and fieldName ~= "tags" and fieldName ~= "metadata" then
			expectedOrder[orderNameForField(fieldName)] = {}
		end
	end
	for _, row in ipairs(EXPECTED_INTEGRATION_ROWS) do
		local order = row[1]
		local compatibility = row[2]
		local declaration = {
			integrationId = "asset.execution.integration." .. order .. "." .. compatibility,
			compatibilityId = "asset.execution.compatibility." .. order .. "." .. compatibility,
			integrationDeclarationId = "asset.execution.declaration."
				.. order
				.. "."
				.. compatibility,
			integrationKind = row[3],
			integrationStatus = row[4],
			runtimeName = "AssetExecutionRuntime",
			providerName = "assetExecutionRuntime",
			snapshotProviderName = "assetExecutionRuntime",
			coordinatorName = "AssetExecutionCoordinator",
			diagnosticsProviderName = "assetExecutionRuntime",
			bootstrapDependencyName = "AssetExecutionAuthorizationCoordinator",
			engineGovernanceSnapshotProviderName = "assetExecutionRuntime",
			documentationReference = row[5],
			authorizationRuntimeName = "AssetExecutionAuthorization",
			authorizationProviderName = "assetExecutionAuthorizationRuntime",
			authorizationSnapshotProviderName = "assetExecutionAuthorizationRuntime",
			readinessEvidenceKind = row[6],
			executionRuntimeName = "AssetExecutionRuntime",
			executionProviderName = "assetExecutionRuntime",
			executionSnapshotProviderName = "assetExecutionRuntime",
			executionCoordinatorName = "AssetExecutionCoordinator",
			adapterBoundaryKind = row[7],
			assetOperationBoundaryKind = row[8],
			required = true,
			evidence = { "asset.execution.integration." .. compatibility .. ".copied" },
			tags = { "asset.execution.integration", "metadata.only" },
			metadata = {
				copied = "true",
				order = order,
				compatibility = compatibility,
				boundary = "metadata.only",
				isolation = "copied",
				futureAdapterAbsent = "true",
				futureAssetOperationsAbsent = "true",
				authoritySeparated = "true",
				executionSeparated = "true",
				gameplaySeparated = "true",
			},
		}
		table.insert(expectedDeclarations, declaration)
		for _, fieldName in ipairs(EXPECTED_INTEGRATION_DECLARATION_FIELDS) do
			if fieldName ~= "evidence" and fieldName ~= "tags" and fieldName ~= "metadata" then
				table.insert(expectedOrder[orderNameForField(fieldName)], declaration[fieldName])
			end
		end
	end
	return expectedDeclarations, expectedOrder
end

local EXPECTED_INTEGRATION_DECLARATIONS, EXPECTED_INTEGRATION_ORDER =
	buildExpectedIntegrationContracts()

local function buildExpectedAdapterReadinessContracts()
	local expectedDeclarations = {}
	local expectedOrder = {}
	for _, fieldName in ipairs(EXPECTED_ADAPTER_READINESS_DECLARATION_FIELDS) do
		if fieldName ~= "evidence" and fieldName ~= "tags" and fieldName ~= "metadata" then
			expectedOrder[orderNameForField(fieldName)] = {}
		end
	end
	for _, row in ipairs(EXPECTED_ADAPTER_READINESS_ROWS) do
		local order = row[1]
		local compatibility = row[2]
		local declaration = {
			readinessId = "asset.execution.adapter.readiness." .. order .. "." .. compatibility,
			compatibilityId = "asset.execution.adapter.compatibility."
				.. order
				.. "."
				.. compatibility,
			adapterReadinessDeclarationId = "asset.execution.adapter.declaration."
				.. order
				.. "."
				.. compatibility,
			readinessKind = row[3],
			readinessStatus = row[4],
			runtimeName = "AssetExecutionRuntime",
			providerName = "assetExecutionRuntime",
			snapshotProviderName = "assetExecutionRuntime",
			coordinatorName = "AssetExecutionCoordinator",
			diagnosticsProviderName = "assetExecutionRuntime",
			bootstrapDependencyName = "AssetExecutionAuthorizationCoordinator",
			engineGovernanceSnapshotProviderName = "assetExecutionRuntime",
			documentationReference = row[5],
			executionRuntimeName = "AssetExecutionRuntime",
			executionProviderName = "assetExecutionRuntime",
			executionSnapshotProviderName = "assetExecutionRuntime",
			executionCoordinatorName = "AssetExecutionCoordinator",
			futureAdapterRuntimeName = "AbsentFutureAdapterRuntime",
			futureAdapterProviderName = "absentFutureAdapterProvider",
			futureAdapterSnapshotProviderName = "absentFutureAdapterSnapshotProvider",
			futureAdapterCoordinatorName = "AbsentFutureAdapterCoordinator",
			adapterKind = row[6],
			adapterAuthorityKind = row[7],
			adapterBoundaryKind = row[8],
			assetOperationBoundaryKind = row[9],
			lifecycleBoundaryKind = row[10],
			required = true,
			evidence = { "asset.execution.adapter.readiness." .. compatibility .. ".copied" },
			tags = { "asset.execution.adapter.readiness", "metadata.only" },
			metadata = {
				copied = "true",
				order = order,
				compatibility = compatibility,
				boundary = "metadata.only",
				isolation = "copied",
				liveAdapterAbsent = "true",
				futureAdapterProviderAbsent = "true",
				futureAdapterSnapshotAbsent = "true",
				futureAssetOperationsAbsent = "true",
				assetOperationPermissionAbsent = "true",
				authoritySeparated = "true",
				clientAuthorityAbsent = "true",
				lifecycleSeparated = "true",
				gameplaySeparated = "true",
			},
		}
		table.insert(expectedDeclarations, declaration)
		for _, fieldName in ipairs(EXPECTED_ADAPTER_READINESS_DECLARATION_FIELDS) do
			if fieldName ~= "evidence" and fieldName ~= "tags" and fieldName ~= "metadata" then
				table.insert(expectedOrder[orderNameForField(fieldName)], declaration[fieldName])
			end
		end
	end
	return expectedDeclarations, expectedOrder
end

local EXPECTED_ADAPTER_READINESS_DECLARATIONS, EXPECTED_ADAPTER_READINESS_ORDER =
	buildExpectedAdapterReadinessContracts()

local function validateDenseArrayShape(values: any, expectedCount: number, label: string)
	if type(values) ~= "table" then
		return false, label .. " must be a table"
	end
	local count = 0
	for key in pairs(values) do
		if type(key) ~= "number" or key ~= math.floor(key) or key < 1 then
			return false, label .. " must be an ordered array"
		end
		count += 1
	end
	if count ~= expectedCount or #values ~= expectedCount then
		return false, label .. " count drift"
	end
	return true, nil
end

local function validateExactScalar(value: any, expected: any, label: string)
	if value ~= expected then
		return false, label .. " drift"
	end
	return true, nil
end

local function validateExactStringArray(values: any, expected: { string }, label: string)
	local shapeOk, shapeReason = validateDenseArrayShape(values, #expected, label)
	if not shapeOk then
		return false, shapeReason
	end
	for index, expectedValue in ipairs(expected) do
		if values[index] ~= expectedValue then
			return false, label .. " value drift"
		end
	end
	return true, nil
end

local function validateSchema(
	schema: any,
	idField: string,
	expectedType: string,
	label: string
): (boolean, string?)
	if schema == nil then
		return false, label .. " schema is nil"
	end
	if type(schema) ~= "table" then
		return false, label .. " schema must be a table"
	end
	local safe, safeReason = Serialization.validateSerializable(schema)
	if not safe then
		return false, safeReason
	end
	local fieldCount = 0
	for key in pairs(schema) do
		fieldCount += 1
		if type(key) ~= "string" or fieldLookup[expectedType][key] ~= true then
			return false, label .. " contains unsupported field"
		end
	end
	if fieldCount ~= Types.SchemaFieldCount[expectedType] then
		return false, label .. " field count is invalid"
	end
	if not validId(schema[idField]) then
		return false, label .. " id is invalid"
	end
	local metadataOk, metadataReason = validateMetadata(schema.metadata, label)
	if not metadataOk then
		return false, metadataReason
	end
	local tagsOk, tagsReason = validateTags(schema.tags)
	if not tagsOk then
		return false, tagsReason
	end
	return validateEvidence(schema.evidence)
end

local function validateIntegrationMetadata(
	metadata: any,
	expectedOrder: string,
	compatibility: string
)
	if type(metadata) ~= "table" then
		return false, "integration metadata is required"
	end
	local expected = {
		copied = "true",
		order = expectedOrder,
		compatibility = compatibility,
		boundary = "metadata.only",
		isolation = "copied",
		futureAdapterAbsent = "true",
		futureAssetOperationsAbsent = "true",
		authoritySeparated = "true",
		executionSeparated = "true",
		gameplaySeparated = "true",
	}
	return validateExactStringMap(metadata, expected, "integration metadata")
end

local function validateIntegrationReadinessDeclarations(): (boolean, string?)
	local declarations = Types.AssetExecutionIntegrationReadinessDeclarations
	local orders = Types.IntegrationReadinessDeclarationOrder
	if type(orders) ~= "table" then
		return false, "integration order must be a table"
	end
	local fieldsOk, fieldsReason = validateExactArray(
		Types.IntegrationReadinessDeclarationFields,
		EXPECTED_INTEGRATION_DECLARATION_FIELDS,
		"integration fields"
	)
	if not fieldsOk then
		return false, fieldsReason
	end
	local declarationShapeOk, declarationShapeReason = validateDenseArrayShape(
		declarations,
		#EXPECTED_INTEGRATION_DECLARATIONS,
		"integration declarations"
	)
	if not declarationShapeOk then
		return false, declarationShapeReason
	end
	local orderKeyCount = 0
	for orderName in pairs(orders) do
		orderKeyCount += 1
		if EXPECTED_INTEGRATION_ORDER[orderName] == nil then
			return false, "integration order contains unsupported table"
		end
	end
	local expectedOrderKeyCount = 0
	for orderName, expectedOrder in pairs(EXPECTED_INTEGRATION_ORDER) do
		expectedOrderKeyCount += 1
		local orderOk, orderReason =
			validateExactStringArray(orders[orderName], expectedOrder, orderName)
		if not orderOk then
			return false, orderReason
		end
	end
	if orderKeyCount ~= expectedOrderKeyCount then
		return false, "integration order table count drift"
	end
	for _, fieldName in ipairs(Types.IntegrationReadinessDeclarationFields) do
		if fieldName ~= "evidence" and fieldName ~= "tags" and fieldName ~= "metadata" then
			local orderName = orderNameForField(fieldName)
			local orderOk, orderReason = validateExactDeclarationArray(
				orders[orderName],
				EXPECTED_INTEGRATION_ORDER[orderName],
				orderName
			)
			if not orderOk then
				return false, orderReason
			end
		end
	end
	local seen: { [string]: boolean } = {}
	for index, declaration in ipairs(declarations) do
		if type(declaration) ~= "table" then
			return false, "integration declaration must be a table"
		end
		local expectedDeclaration = EXPECTED_INTEGRATION_DECLARATIONS[index]
		local fieldCount = 0
		local integrationFieldLookup = {}
		for _, fieldName in ipairs(Types.IntegrationReadinessDeclarationFields) do
			integrationFieldLookup[fieldName] = true
		end
		for key in pairs(declaration) do
			fieldCount += 1
			if type(key) ~= "string" or integrationFieldLookup[key] ~= true then
				return false, "integration declaration contains unsupported field"
			end
		end
		if fieldCount ~= #Types.IntegrationReadinessDeclarationFields then
			return false, "integration declaration field count drift"
		end
		local safe, safeReason = Serialization.validateSerializable(declaration)
		if not safe then
			return false, safeReason
		end
		for _, idField in ipairs({
			"integrationId",
			"compatibilityId",
			"integrationDeclarationId",
		}) do
			if not validId(declaration[idField]) then
				return false, idField .. " is invalid"
			end
			if seen[declaration[idField]] then
				return false, idField .. " is duplicate"
			end
			seen[declaration[idField]] = true
		end
		for _, fieldName in ipairs(Types.IntegrationReadinessDeclarationFields) do
			if fieldName ~= "evidence" and fieldName ~= "tags" and fieldName ~= "metadata" then
				local orderExpected = orders[orderNameForField(fieldName)][index]
				if declaration[fieldName] ~= orderExpected then
					return false, fieldName .. " order drift"
				end
				local scalarOk, scalarReason = validateExactScalar(
					declaration[fieldName],
					expectedDeclaration[fieldName],
					fieldName
				)
				if not scalarOk then
					return false, scalarReason
				end
			end
		end
		if Types.IntegrationKind[declaration.integrationKind] ~= true then
			return false, "integrationKind is invalid"
		end
		if Types.IntegrationStatus[declaration.integrationStatus] ~= true then
			return false, "integrationStatus is invalid"
		end
		if Types.AdapterBoundaryKind[declaration.adapterBoundaryKind] ~= true then
			return false, "adapterBoundaryKind is invalid"
		end
		if Types.AssetOperationBoundaryKind[declaration.assetOperationBoundaryKind] ~= true then
			return false, "assetOperationBoundaryKind is invalid"
		end
		if declaration.required ~= true then
			return false, "integration required drift"
		end
		local evidenceOk, evidenceReason = validateEvidence(declaration.evidence)
		if not evidenceOk then
			return false, evidenceReason
		end
		local exactEvidenceOk, exactEvidenceReason = validateExactStringArray(
			declaration.evidence,
			expectedDeclaration.evidence,
			"integration evidence"
		)
		if not exactEvidenceOk then
			return false, exactEvidenceReason
		end
		local tagsOk, tagsReason = validateTags(declaration.tags)
		if not tagsOk then
			return false, tagsReason
		end
		local exactTagsOk, exactTagsReason =
			validateExactStringArray(declaration.tags, expectedDeclaration.tags, "integration tags")
		if not exactTagsOk then
			return false, exactTagsReason
		end
		local metadataOk, metadataReason = validateIntegrationMetadata(
			declaration.metadata,
			expectedDeclaration.metadata.order,
			expectedDeclaration.metadata.compatibility
		)
		if not metadataOk then
			return false, metadataReason
		end
	end
	return true, nil
end

local function validateAdapterReadinessMetadata(
	metadata: any,
	expectedOrder: string,
	compatibility: string
)
	if type(metadata) ~= "table" then
		return false, "adapter readiness metadata is required"
	end
	local expected = {
		copied = "true",
		order = expectedOrder,
		compatibility = compatibility,
		boundary = "metadata.only",
		isolation = "copied",
		liveAdapterAbsent = "true",
		futureAdapterProviderAbsent = "true",
		futureAdapterSnapshotAbsent = "true",
		futureAssetOperationsAbsent = "true",
		assetOperationPermissionAbsent = "true",
		authoritySeparated = "true",
		clientAuthorityAbsent = "true",
		lifecycleSeparated = "true",
		gameplaySeparated = "true",
	}
	return validateExactStringMap(metadata, expected, "adapter readiness metadata")
end

local function validateAdapterReadinessDeclarations(): (boolean, string?)
	local declarations = Types.AssetExecutionAdapterReadinessDeclarations
	local orders = Types.AdapterReadinessDeclarationOrder
	if type(orders) ~= "table" then
		return false, "adapter readiness order must be a table"
	end
	local fieldsOk, fieldsReason = validateExactArray(
		Types.AdapterReadinessDeclarationFields,
		EXPECTED_ADAPTER_READINESS_DECLARATION_FIELDS,
		"adapter readiness fields"
	)
	if not fieldsOk then
		return false, fieldsReason
	end
	local declarationShapeOk, declarationShapeReason = validateDenseArrayShape(
		declarations,
		#EXPECTED_ADAPTER_READINESS_DECLARATIONS,
		"adapter readiness declarations"
	)
	if not declarationShapeOk then
		return false, declarationShapeReason
	end
	local orderKeyCount = 0
	for orderName in pairs(orders) do
		orderKeyCount += 1
		if EXPECTED_ADAPTER_READINESS_ORDER[orderName] == nil then
			return false, "adapter readiness order contains unsupported table"
		end
	end
	local expectedOrderKeyCount = 0
	for orderName, expectedOrder in pairs(EXPECTED_ADAPTER_READINESS_ORDER) do
		expectedOrderKeyCount += 1
		local orderOk, orderReason =
			validateExactStringArray(orders[orderName], expectedOrder, orderName)
		if not orderOk then
			return false, orderReason
		end
	end
	if orderKeyCount ~= expectedOrderKeyCount then
		return false, "adapter readiness order table count drift"
	end
	for _, fieldName in ipairs(Types.AdapterReadinessDeclarationFields) do
		if fieldName ~= "evidence" and fieldName ~= "tags" and fieldName ~= "metadata" then
			local orderName = orderNameForField(fieldName)
			local orderOk, orderReason = validateExactDeclarationArray(
				orders[orderName],
				EXPECTED_ADAPTER_READINESS_ORDER[orderName],
				orderName
			)
			if not orderOk then
				return false, orderReason
			end
		end
	end
	local seen: { [string]: boolean } = {}
	for index, declaration in ipairs(declarations) do
		if type(declaration) ~= "table" then
			return false, "adapter readiness declaration must be a table"
		end
		local expectedDeclaration = EXPECTED_ADAPTER_READINESS_DECLARATIONS[index]
		local fieldCount = 0
		local adapterReadinessFieldLookup = {}
		for _, fieldName in ipairs(Types.AdapterReadinessDeclarationFields) do
			adapterReadinessFieldLookup[fieldName] = true
		end
		for key in pairs(declaration) do
			fieldCount += 1
			if type(key) ~= "string" or adapterReadinessFieldLookup[key] ~= true then
				return false, "adapter readiness declaration contains unsupported field"
			end
		end
		if fieldCount ~= #Types.AdapterReadinessDeclarationFields then
			return false, "adapter readiness declaration field count drift"
		end
		local safe, safeReason = Serialization.validateSerializable(declaration)
		if not safe then
			return false, safeReason
		end
		for _, idField in ipairs({
			"readinessId",
			"compatibilityId",
			"adapterReadinessDeclarationId",
		}) do
			if not validId(declaration[idField]) then
				return false, idField .. " is invalid"
			end
			if seen[declaration[idField]] then
				return false, idField .. " is duplicate"
			end
			seen[declaration[idField]] = true
		end
		for _, fieldName in ipairs(Types.AdapterReadinessDeclarationFields) do
			if fieldName ~= "evidence" and fieldName ~= "tags" and fieldName ~= "metadata" then
				local orderExpected = orders[orderNameForField(fieldName)][index]
				if declaration[fieldName] ~= orderExpected then
					return false, fieldName .. " order drift"
				end
				local scalarOk, scalarReason = validateExactScalar(
					declaration[fieldName],
					expectedDeclaration[fieldName],
					fieldName
				)
				if not scalarOk then
					return false, scalarReason
				end
			end
		end
		if Types.AdapterReadinessKind[declaration.readinessKind] ~= true then
			return false, "readinessKind is invalid"
		end
		if Types.AdapterReadinessStatus[declaration.readinessStatus] ~= true then
			return false, "readinessStatus is invalid"
		end
		if Types.FutureAdapterKind[declaration.adapterKind] ~= true then
			return false, "adapterKind is invalid"
		end
		if Types.AdapterAuthorityKind[declaration.adapterAuthorityKind] ~= true then
			return false, "adapterAuthorityKind is invalid"
		end
		if Types.AdapterReadinessBoundaryKind[declaration.adapterBoundaryKind] ~= true then
			return false, "adapterBoundaryKind is invalid"
		end
		if
			Types.AdapterAssetOperationBoundaryKind[declaration.assetOperationBoundaryKind]
			~= true
		then
			return false, "assetOperationBoundaryKind is invalid"
		end
		if Types.AdapterLifecycleBoundaryKind[declaration.lifecycleBoundaryKind] ~= true then
			return false, "lifecycleBoundaryKind is invalid"
		end
		if declaration.required ~= true then
			return false, "adapter readiness required drift"
		end
		local evidenceOk, evidenceReason = validateEvidence(declaration.evidence)
		if not evidenceOk then
			return false, evidenceReason
		end
		local exactEvidenceOk, exactEvidenceReason = validateExactStringArray(
			declaration.evidence,
			expectedDeclaration.evidence,
			"adapter readiness evidence"
		)
		if not exactEvidenceOk then
			return false, exactEvidenceReason
		end
		local tagsOk, tagsReason = validateTags(declaration.tags)
		if not tagsOk then
			return false, tagsReason
		end
		local exactTagsOk, exactTagsReason = validateExactStringArray(
			declaration.tags,
			expectedDeclaration.tags,
			"adapter readiness tags"
		)
		if not exactTagsOk then
			return false, exactTagsReason
		end
		local metadataOk, metadataReason = validateAdapterReadinessMetadata(
			declaration.metadata,
			expectedDeclaration.metadata.order,
			expectedDeclaration.metadata.compatibility
		)
		if not metadataOk then
			return false, metadataReason
		end
	end
	return true, nil
end

function Validation.runtime(schema: any): (boolean, string?)
	local ok, reason =
		validateSchema(schema, "runtimeId", Types.SchemaType.ExecutionRuntime, "runtime")
	if not ok then
		return false, reason
	end
	if not validId(schema.authorizationId) or not validId(schema.readinessId) then
		return false, "runtime references are invalid"
	end
	if Types.RuntimeKind[schema.runtimeKind] ~= true then
		return false, "runtimeKind is invalid"
	end
	if Types.RuntimeStatus[schema.runtimeStatus] ~= true then
		return false, "runtimeStatus is invalid"
	end
	if schema.providerName ~= Types.RuntimeProviderName then
		return false, "providerName drift"
	end
	if schema.snapshotProviderName ~= Types.RuntimeProviderName then
		return false, "snapshotProviderName drift"
	end
	for _, group in ipairs({
		{ schema.requestIds, "requestIds" },
		{ schema.boundaryIds, "boundaryIds" },
		{ schema.auditIds, "auditIds" },
	}) do
		if group[1] == nil then
			return false, group[2] .. " are required"
		end
		local listOk, listReason =
			validateArrayIds(group[1], Types.Limits.MaxChildReferences, group[2])
		if not listOk then
			return false, listReason
		end
	end
	return true, nil
end

function Validation.request(schema: any): (boolean, string?)
	local ok, reason =
		validateSchema(schema, "requestId", Types.SchemaType.ExecutionRequest, "request")
	if not ok then
		return false, reason
	end
	if not validId(schema.runtimeId) or not validId(schema.requestedBy) then
		return false, "request references are invalid"
	end
	if Types.RequestKind[schema.requestKind] ~= true then
		return false, "requestKind is invalid"
	end
	if Types.RequestStatus[schema.requestStatus] ~= true then
		return false, "requestStatus is invalid"
	end
	return true, nil
end

function Validation.boundary(schema: any): (boolean, string?)
	local ok, reason =
		validateSchema(schema, "boundaryId", Types.SchemaType.ExecutionBoundary, "boundary")
	if not ok then
		return false, reason
	end
	if not validId(schema.runtimeId) then
		return false, "boundary runtimeId is invalid"
	end
	if Types.BoundaryKind[schema.boundaryKind] ~= true then
		return false, "boundaryKind is invalid"
	end
	if Types.BoundaryStatus[schema.boundaryStatus] ~= true then
		return false, "boundaryStatus is invalid"
	end
	if
		type(schema.summary) ~= "string"
		or schema.summary == ""
		or #schema.summary > Types.Limits.MaxSummaryLength
	then
		return false, "boundary summary is invalid"
	end
	return true, nil
end

function Validation.audit(schema: any): (boolean, string?)
	local ok, reason = validateSchema(schema, "auditId", Types.SchemaType.ExecutionAudit, "audit")
	if not ok then
		return false, reason
	end
	if not validId(schema.runtimeId) or not validId(schema.reviewer) then
		return false, "audit references are invalid"
	end
	if Types.AuditKind[schema.auditKind] ~= true then
		return false, "auditKind is invalid"
	end
	if Types.AuditStatus[schema.auditStatus] ~= true then
		return false, "auditStatus is invalid"
	end
	for _, group in ipairs({
		{ schema.requestIds, "requestIds" },
		{ schema.boundaryIds, "boundaryIds" },
	}) do
		if group[1] == nil then
			return false, group[2] .. " are required"
		end
		local listOk, listReason =
			validateArrayIds(group[1], Types.Limits.MaxChildReferences, group[2])
		if not listOk then
			return false, listReason
		end
	end
	return true, nil
end

function Validation.validate(): (boolean, string?)
	if Types.RuntimeProviderName ~= "assetExecutionRuntime" then
		return false, "provider name drift"
	end
	if Types.SnapshotKind ~= "assetExecutionRuntimeSnapshot" then
		return false, "snapshot kind drift"
	end
	if Types.RuntimeName ~= "AssetExecutionRuntime" then
		return false, "runtime name drift"
	end
	if Types.CoordinatorName ~= "AssetExecutionCoordinator" then
		return false, "coordinator name drift"
	end
	for schemaName, expectedFields in pairs(EXPECTED_SCHEMA_FIELDS) do
		local fieldsOk, fieldsReason =
			validateExactArray(Types.SchemaFields[schemaName], expectedFields, schemaName)
		if not fieldsOk then
			return false, fieldsReason
		end
		if Types.SchemaFieldCount[schemaName] ~= #expectedFields then
			return false, schemaName .. " field count drift"
		end
	end
	for enumName, expectedValues in pairs(EXPECTED_ENUMS) do
		local enumOk, enumReason = validateExactBoolMap(Types[enumName], expectedValues, enumName)
		if not enumOk then
			return false, enumReason
		end
	end
	local limitsOk, limitsReason = validateExactNumberMap(Types.Limits, EXPECTED_LIMITS, "limits")
	if not limitsOk then
		return false, limitsReason
	end
	local postureOk, postureReason =
		validateExactArray(Types.PostureKeys, EXPECTED_POSTURE_KEYS, "posture keys")
	if not postureOk then
		return false, postureReason
	end
	local apiOk, apiReason =
		validateExactArray(Types.CoordinatorApiOrder, EXPECTED_COORDINATOR_API, "coordinator API")
	if not apiOk then
		return false, apiReason
	end
	local signalsOk, signalsReason =
		validateExactStringMap(Types.SignalNames, EXPECTED_SIGNAL_NAMES, "signals")
	if not signalsOk then
		return false, signalsReason
	end
	local docsOk, docsReason = validateExactArray(Types.DocumentationFiles, {
		"ASSET_EXECUTION_RUNTIME.md",
		"ASSET_EXECUTION_VALIDATION.md",
		"ASSET_EXECUTION_SERIALIZATION.md",
		"ASSET_EXECUTION_DIAGNOSTICS.md",
		"ASSET_EXECUTION_RUNTIME_LIMITS.md",
		"ASSET_EXECUTION_SELF_CHECKS.md",
		"ASSET_EXECUTION_PRODUCTION_REVIEW.md",
		"ASSET_EXECUTION_AUDIT.md",
		"ASSET_EXECUTION_RUNTIME_INTEGRATION_READINESS.md",
		"ASSET_EXECUTION_ADAPTER_READINESS.md",
		"ASSET_EXECUTION_ADAPTER_READINESS_VALIDATION.md",
		"ASSET_EXECUTION_ADAPTER_READINESS_DIAGNOSTICS.md",
		"ASSET_EXECUTION_ADAPTER_READINESS_SELF_CHECKS.md",
		"ASSET_EXECUTION_ADAPTER_READINESS_PRODUCTION_REVIEW.md",
		"EXECUTION_RUNTIME.md",
		"EXECUTION_REQUEST_RUNTIME.md",
		"EXECUTION_BOUNDARY_RUNTIME.md",
		"EXECUTION_AUDIT_RUNTIME.md",
	}, "documentation")
	if not docsOk then
		return false, docsReason
	end
	local bootstrapOk, bootstrapReason = validateExactArray(
		Types.BootstrapDependencyOrder,
		{ "AssetExecutionAuthorizationCoordinator" },
		"Bootstrap dependency"
	)
	if not bootstrapOk then
		return false, bootstrapReason
	end
	local governanceOk, governanceReason = validateExactArray(
		Types.GovernanceSnapshotProviders,
		{ Types.RuntimeProviderName },
		"Governance snapshot provider"
	)
	if not governanceOk then
		return false, governanceReason
	end
	local integrationOk, integrationReason = validateIntegrationReadinessDeclarations()
	if not integrationOk then
		return false, integrationReason
	end
	local adapterReadinessOk, adapterReadinessReason = validateAdapterReadinessDeclarations()
	if not adapterReadinessOk then
		return false, adapterReadinessReason
	end
	return true, nil
end

Validation.validId = validId
Validation.integrationReadiness = validateIntegrationReadinessDeclarations
Validation.adapterReadiness = validateAdapterReadinessDeclarations

return Validation

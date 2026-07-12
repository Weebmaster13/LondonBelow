--!strict

local Types = {}

Types.Mode = "ServerAuthoritativeAssetExecutionMetadataRuntime"
Types.RuntimeProviderName = "assetExecutionRuntime"
Types.SnapshotKind = "assetExecutionRuntimeSnapshot"
Types.RuntimeName = "AssetExecutionRuntime"
Types.CoordinatorName = "AssetExecutionCoordinator"

Types.CoordinatorApiOrder = {
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

Types.SignalNames = {
	Initialized = "AssetExecutionRuntime.Initialized",
	Started = "AssetExecutionRuntime.Started",
	Shutdown = "AssetExecutionRuntime.Shutdown",
	ValidationFailed = "AssetExecutionRuntime.ValidationFailed",
}

Types.SchemaType = {
	ExecutionRuntime = "ExecutionRuntime",
	ExecutionRequest = "ExecutionRequest",
	ExecutionBoundary = "ExecutionBoundary",
	ExecutionAudit = "ExecutionAudit",
}

Types.SchemaFields = {
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

Types.SchemaFieldCount = {}
for schemaName, fields in pairs(Types.SchemaFields) do
	Types.SchemaFieldCount[schemaName] = #fields
end

Types.IntegrationReadinessDeclarationFields = {
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

Types.RuntimeKind = {
	MetadataRuntime = true,
	RequestRuntime = true,
	BoundaryRuntime = true,
	AuditRuntime = true,
	FuturePipelineRuntime = true,
}

Types.RuntimeStatus = {
	Declared = true,
	Ready = true,
	Deferred = true,
	Warning = true,
	Blocked = true,
}

Types.RequestKind = {
	RuntimeMetadataRequest = true,
	ReadinessMetadataRequest = true,
	BoundaryMetadataRequest = true,
	AuditMetadataRequest = true,
	FuturePipelineRequest = true,
}

Types.RequestStatus = {
	Declared = true,
	Validated = true,
	Deferred = true,
	Warning = true,
	Blocked = true,
}

Types.BoundaryKind = {
	NoAssetLoading = true,
	NoAssetStreaming = true,
	NoAssetSpawning = true,
	NoAssetApplication = true,
	NoAssetPlayback = true,
	NoPresentation = true,
	NoSave = true,
	NoGameplay = true,
	NoNetworking = true,
	NoWorldMutation = true,
	NoPersistence = true,
	NoRouting = true,
	NoDispatch = true,
	NoQueueing = true,
	NoScheduling = true,
	NoOrchestration = true,
}

Types.BoundaryStatus = {
	Declared = true,
	Satisfied = true,
	Deferred = true,
	Warning = true,
	Blocked = true,
}

Types.AuditKind = {
	RuntimeAudit = true,
	RequestAudit = true,
	BoundaryAudit = true,
	ProductionAudit = true,
}

Types.AuditStatus = {
	Passed = true,
	Failed = true,
	Warning = true,
	Deferred = true,
	Blocked = true,
}

Types.IntegrationKind = {
	AuthorizationRuntimeCompatibility = true,
	AuthorizationProviderCompatibility = true,
	AuthorizationSnapshotCompatibility = true,
	ExecutionReadinessCompatibility = true,
	ExecutionRuntimeCompatibility = true,
	ExecutionProviderCompatibility = true,
	ExecutionSnapshotCompatibility = true,
	ExecutionCoordinatorCompatibility = true,
	BootstrapCompatibility = true,
	EngineGovernanceCompatibility = true,
	DocumentationCompatibility = true,
	SchemaCompatibility = true,
	EnumCompatibility = true,
	ReferenceIntegrityCompatibility = true,
	SerializationCompatibility = true,
	DiagnosticsCompatibility = true,
	SnapshotIsolationCompatibility = true,
	RuntimeLimitCompatibility = true,
	SignalBoundaryCompatibility = true,
	CoordinatorBoundaryCompatibility = true,
	LifecycleCompatibility = true,
	FutureAdapterSeparation = true,
	FutureAssetOperationSeparation = true,
	FutureGameplaySeparation = true,
}

Types.IntegrationStatus = {
	Declared = true,
	Compatible = true,
	IntegrationReady = true,
	BoundaryReady = true,
	ObservationOnly = true,
	Deferred = true,
	Warning = true,
	Blocked = true,
}

Types.AdapterBoundaryKind = {
	NoExecutionAdapter = true,
	NoAssetLoaderAdapter = true,
	NoAssetSpawnAdapter = true,
	NoAssetApplicationAdapter = true,
	NoAssetPlaybackAdapter = true,
	NoRoutingAdapter = true,
	NoDispatchAdapter = true,
	NoQueueAdapter = true,
	NoSchedulerAdapter = true,
	NoOrchestrationAdapter = true,
	FutureAdapterSeparate = true,
}

Types.AssetOperationBoundaryKind = {
	NoAssetLoading = true,
	NoAssetPreloading = true,
	NoAssetStreaming = true,
	NoAssetSpawning = true,
	NoAssetCloning = true,
	NoAssetInsertion = true,
	NoAssetApplication = true,
	NoAssetDisplay = true,
	NoAssetPlayback = true,
	NoAnimationPlayback = true,
	NoAudioPlayback = true,
	NoWorldMutation = true,
	NoStorageMutation = true,
	NoNetworkOwnership = true,
	NoPhysicsExecution = true,
	NoGameplayExecution = true,
	FutureAssetOperationsSeparate = true,
	FutureGameplaySeparate = true,
}

local function orderNameForField(fieldName: string): string
	return string.upper(string.sub(fieldName, 1, 1)) .. string.sub(fieldName, 2) .. "Order"
end

local INTEGRATION_ROWS = {
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

Types.AssetExecutionIntegrationReadinessDeclarations = {}
Types.IntegrationReadinessDeclarationOrder = {}
for _, fieldName in ipairs(Types.IntegrationReadinessDeclarationFields) do
	if fieldName ~= "evidence" and fieldName ~= "tags" and fieldName ~= "metadata" then
		Types.IntegrationReadinessDeclarationOrder[orderNameForField(fieldName)] = {}
	end
end

for _, row in ipairs(INTEGRATION_ROWS) do
	local order = row[1]
	local compatibility = row[2]
	local declaration = {
		integrationId = "asset.execution.integration." .. order .. "." .. compatibility,
		compatibilityId = "asset.execution.compatibility." .. order .. "." .. compatibility,
		integrationDeclarationId = "asset.execution.declaration." .. order .. "." .. compatibility,
		integrationKind = row[3],
		integrationStatus = row[4],
		runtimeName = Types.RuntimeName,
		providerName = Types.RuntimeProviderName,
		snapshotProviderName = Types.RuntimeProviderName,
		coordinatorName = Types.CoordinatorName,
		diagnosticsProviderName = Types.RuntimeProviderName,
		bootstrapDependencyName = "AssetExecutionAuthorizationCoordinator",
		engineGovernanceSnapshotProviderName = Types.RuntimeProviderName,
		documentationReference = row[5],
		authorizationRuntimeName = "AssetExecutionAuthorization",
		authorizationProviderName = "assetExecutionAuthorizationRuntime",
		authorizationSnapshotProviderName = "assetExecutionAuthorizationRuntime",
		readinessEvidenceKind = row[6],
		executionRuntimeName = Types.RuntimeName,
		executionProviderName = Types.RuntimeProviderName,
		executionSnapshotProviderName = Types.RuntimeProviderName,
		executionCoordinatorName = Types.CoordinatorName,
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
	table.insert(Types.AssetExecutionIntegrationReadinessDeclarations, declaration)
	for _, fieldName in ipairs(Types.IntegrationReadinessDeclarationFields) do
		if fieldName ~= "evidence" and fieldName ~= "tags" and fieldName ~= "metadata" then
			table.insert(
				Types.IntegrationReadinessDeclarationOrder[orderNameForField(fieldName)],
				declaration[fieldName]
			)
		end
	end
end

Types.PostureKeys = {
	"assetExecutionRuntimePosture",
	"assetExecutionRequestPosture",
	"assetExecutionBoundaryPosture",
	"assetExecutionAuditPosture",
	"assetExecutionIntegrationReadinessPosture",
	"assetExecutionCompatibilityPosture",
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

Types.DocumentationFiles = {
	"ASSET_EXECUTION_RUNTIME.md",
	"ASSET_EXECUTION_VALIDATION.md",
	"ASSET_EXECUTION_SERIALIZATION.md",
	"ASSET_EXECUTION_DIAGNOSTICS.md",
	"ASSET_EXECUTION_RUNTIME_LIMITS.md",
	"ASSET_EXECUTION_SELF_CHECKS.md",
	"ASSET_EXECUTION_PRODUCTION_REVIEW.md",
	"ASSET_EXECUTION_AUDIT.md",
	"ASSET_EXECUTION_RUNTIME_INTEGRATION_READINESS.md",
	"EXECUTION_RUNTIME.md",
	"EXECUTION_REQUEST_RUNTIME.md",
	"EXECUTION_BOUNDARY_RUNTIME.md",
	"EXECUTION_AUDIT_RUNTIME.md",
}

Types.BootstrapDependencyOrder = {
	"AssetExecutionAuthorizationCoordinator",
}

Types.GovernanceSnapshotProviders = {
	"assetExecutionRuntime",
}

Types.Limits = {
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

return Types

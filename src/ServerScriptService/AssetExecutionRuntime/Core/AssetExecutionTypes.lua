--!strict

local Types = {}

Types.Mode = "ServerAuthoritativeAssetExecutionMetadataRuntime"
Types.RuntimeProviderName = "assetExecutionRuntime"
Types.SnapshotKind = "assetExecutionRuntimeSnapshot"
Types.RuntimeName = "AssetExecutionRuntime"
Types.CoordinatorName = "AssetExecutionCoordinator"

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

Types.PostureKeys = {
	"assetExecutionRuntimePosture",
	"assetExecutionRequestPosture",
	"assetExecutionBoundaryPosture",
	"assetExecutionAuditPosture",
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

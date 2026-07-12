--!strict

local Types = {}

Types.Mode = "ServerAuthoritativeAssetExecutionAdapterMetadataRuntime"
Types.RuntimeProviderName = "assetExecutionAdapterRuntime"
Types.SnapshotKind = "assetExecutionAdapterRuntimeSnapshot"
Types.RuntimeName = "AssetExecutionAdapterRuntime"
Types.CoordinatorName = "AssetExecutionAdapterCoordinator"

Types.CoordinatorApiOrder = {
	"initialize",
	"start",
	"shutdown",
	"registerExecutionAdapter",
	"registerExecutionAdapterCapability",
	"registerExecutionAdapterCompatibility",
	"registerExecutionAdapterBoundary",
	"registerExecutionAdapterAudit",
	"inspect",
	"getSnapshot",
	"validate",
	"runSelfChecks",
}

Types.SignalNames = {
	Initialized = "AssetExecutionAdapterRuntime.Initialized",
	Started = "AssetExecutionAdapterRuntime.Started",
	Shutdown = "AssetExecutionAdapterRuntime.Shutdown",
	ValidationFailed = "AssetExecutionAdapterRuntime.ValidationFailed",
}

Types.SchemaType = {
	ExecutionAdapter = "ExecutionAdapter",
	ExecutionAdapterCapability = "ExecutionAdapterCapability",
	ExecutionAdapterCompatibility = "ExecutionAdapterCompatibility",
	ExecutionAdapterBoundary = "ExecutionAdapterBoundary",
	ExecutionAdapterAudit = "ExecutionAdapterAudit",
}

Types.SchemaFields = {
	ExecutionAdapter = {
		"adapterId",
		"adapterName",
		"contractId",
		"runtimeId",
		"adapterKind",
		"adapterStatus",
		"providerName",
		"snapshotProviderName",
		"capabilityIds",
		"compatibilityIds",
		"boundaryIds",
		"auditIds",
		"evidence",
		"tags",
		"metadata",
	},
	ExecutionAdapterCapability = {
		"capabilityId",
		"adapterId",
		"capabilityKind",
		"capabilityStatus",
		"summary",
		"evidence",
		"tags",
		"metadata",
	},
	ExecutionAdapterCompatibility = {
		"compatibilityId",
		"adapterId",
		"compatibilityKind",
		"compatibilityStatus",
		"targetRuntimeName",
		"evidence",
		"tags",
		"metadata",
	},
	ExecutionAdapterBoundary = {
		"boundaryId",
		"adapterId",
		"boundaryKind",
		"boundaryStatus",
		"summary",
		"evidence",
		"tags",
		"metadata",
	},
	ExecutionAdapterAudit = {
		"auditId",
		"adapterId",
		"capabilityIds",
		"compatibilityIds",
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

Types.AdapterKind = {
	MetadataAdapter = true,
	AssetAcquisitionAdapterMetadata = true,
	AssetFormationAdapterMetadata = true,
	AssetApplicationAdapterMetadata = true,
	AssetPresentationAdapterMetadata = true,
	AudioAdapterMetadata = true,
	AnimationAdapterMetadata = true,
	OperationBoundaryAdapterMetadata = true,
}

Types.AdapterStatus = {
	Declared = true,
	Registered = true,
	Compatible = true,
	Deferred = true,
	Warning = true,
	Blocked = true,
}

Types.CapabilityKind = {
	AssetAcquisitionCapabilityMetadata = true,
	AssetFormationCapabilityMetadata = true,
	AssetApplicationCapabilityMetadata = true,
	PresentationInstructionCapabilityMetadata = true,
	AudioInstructionCapabilityMetadata = true,
	AnimationInstructionCapabilityMetadata = true,
	BoundaryDeclarationCapabilityMetadata = true,
	NoExecutionCapability = true,
}

Types.CapabilityStatus = {
	Declared = true,
	Compatible = true,
	Deferred = true,
	Warning = true,
	Blocked = true,
}

Types.CompatibilityKind = {
	RuntimeCompatibility = true,
	AuthorizationCompatibility = true,
	GovernanceCompatibility = true,
	ContractCompatibility = true,
	ImplementationReadinessCompatibility = true,
	ProviderCompatibility = true,
	SnapshotCompatibility = true,
	DiagnosticsCompatibility = true,
}

Types.CompatibilityStatus = {
	Declared = true,
	Compatible = true,
	Deferred = true,
	Warning = true,
	Blocked = true,
}

Types.BoundaryKind = {
	NoAssetLoading = true,
	NoAssetPreloading = true,
	NoAssetStreaming = true,
	NoAssetSpawning = true,
	NoAssetApplication = true,
	NoAssetPlayback = true,
	NoAnimationPlayback = true,
	NoAudioPlayback = true,
	NoModelCreation = true,
	NoInterfaceSurface = true,
	NoVisualEffects = true,
	NoWorldMutation = true,
	NoStorageMutation = true,
	NoNetworkOwnership = true,
	NoPhysicsExecution = true,
	NoRouting = true,
	NoDispatch = true,
	NoQueueing = true,
	NoScheduling = true,
	NoOrchestration = true,
	NoGameplay = true,
	NoPresentation = true,
	NoSave = true,
	NoChapter = true,
}

Types.BoundaryStatus = {
	Declared = true,
	Satisfied = true,
	Deferred = true,
	Warning = true,
	Blocked = true,
}

Types.AuditKind = {
	AdapterAudit = true,
	CapabilityAudit = true,
	CompatibilityAudit = true,
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
	"assetExecutionAdapterRuntimePosture",
	"assetExecutionAdapterValidationPosture",
	"assetExecutionAdapterCompatibilityPosture",
	"assetExecutionAdapterLifecyclePosture",
	"assetExecutionAdapterCapabilityPosture",
	"assetExecutionAdapterBoundaryPosture",
	"assetExecutionAdapterAuditPosture",
	"assetExecutionAdapterCertificationPosture",
	"assetExecutionAdapterSchemaPosture",
	"assetExecutionAdapterEnumPosture",
	"assetExecutionAdapterReferencePosture",
	"assetExecutionAdapterArrayPosture",
	"assetExecutionAdapterLimitPosture",
	"assetExecutionAdapterSignalPosture",
	"assetExecutionAdapterCoordinatorBoundaryPosture",
	"assetExecutionAdapterIsolationPosture",
	"assetExecutionAdapterNoImplementationPosture",
	"assetExecutionAdapterNoRegistryPosture",
	"assetExecutionAdapterNoOperationPosture",
	"assetExecutionAdapterNoAuthorityPosture",
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
	"ASSET_EXECUTION_ADAPTER_RUNTIME.md",
	"ASSET_EXECUTION_ADAPTER_VALIDATION.md",
	"ASSET_EXECUTION_ADAPTER_SERIALIZATION.md",
	"ASSET_EXECUTION_ADAPTER_DIAGNOSTICS.md",
	"ASSET_EXECUTION_ADAPTER_SNAPSHOTS.md",
	"ASSET_EXECUTION_ADAPTER_AUDIT.md",
	"ASSET_EXECUTION_ADAPTER_SELF_CHECKS.md",
	"ASSET_EXECUTION_ADAPTER_PRODUCTION_REVIEW.md",
}

Types.BootstrapDependencyOrder = {
	"AssetExecutionCoordinator",
}

Types.GovernanceSnapshotProviders = {
	"assetExecutionAdapterRuntime",
}

Types.Limits = {
	MaxAdapters = 160,
	MaxCapabilities = 480,
	MaxCompatibilities = 320,
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

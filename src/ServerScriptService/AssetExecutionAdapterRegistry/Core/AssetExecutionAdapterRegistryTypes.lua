--!strict

local Types = {}

Types.Mode = "ServerAuthoritativeAssetExecutionAdapterRegistryMetadataRuntime"
Types.RuntimeProviderName = "assetExecutionAdapterRegistry"
Types.SnapshotKind = "assetExecutionAdapterRegistrySnapshot"
Types.RuntimeName = "AssetExecutionAdapterRegistry"
Types.CoordinatorName = "AssetExecutionAdapterRegistryCoordinator"

Types.CoordinatorApiOrder = {
	"initialize",
	"start",
	"shutdown",
	"registerExecutionAdapterRegistry",
	"registerExecutionAdapterRegistration",
	"registerExecutionAdapterRegistrationBoundary",
	"registerExecutionAdapterRegistryCompatibility",
	"registerExecutionAdapterRegistrationAudit",
	"registerExecutionAdapterRegistrySnapshot",
	"inspect",
	"getSnapshot",
	"validate",
	"runSelfChecks",
}

Types.SignalNames = {
	Initialized = "AssetExecutionAdapterRegistry.Initialized",
	Started = "AssetExecutionAdapterRegistry.Started",
	Shutdown = "AssetExecutionAdapterRegistry.Shutdown",
	ValidationFailed = "AssetExecutionAdapterRegistry.ValidationFailed",
}

Types.SchemaType = {
	ExecutionAdapterRegistry = "ExecutionAdapterRegistry",
	ExecutionAdapterRegistration = "ExecutionAdapterRegistration",
	ExecutionAdapterRegistrationAudit = "ExecutionAdapterRegistrationAudit",
	ExecutionAdapterRegistrationBoundary = "ExecutionAdapterRegistrationBoundary",
	ExecutionAdapterRegistrySnapshot = "ExecutionAdapterRegistrySnapshot",
	ExecutionAdapterRegistryCompatibility = "ExecutionAdapterRegistryCompatibility",
}

Types.SchemaFields = {
	ExecutionAdapterRegistry = {
		"registryId",
		"registryName",
		"providerName",
		"snapshotProviderName",
		"registryKind",
		"registryStatus",
		"registrationIds",
		"compatibilityIds",
		"boundaryIds",
		"auditIds",
		"snapshotIds",
		"evidence",
		"tags",
		"metadata",
	},
	ExecutionAdapterRegistration = {
		"registrationId",
		"registryId",
		"adapterId",
		"adapterName",
		"adapterProviderName",
		"adapterSnapshotProviderName",
		"contractId",
		"runtimeId",
		"registrationKind",
		"registrationStatus",
		"owner",
		"evidence",
		"tags",
		"metadata",
	},
	ExecutionAdapterRegistrationAudit = {
		"auditId",
		"registryId",
		"registrationId",
		"boundaryIds",
		"compatibilityIds",
		"auditKind",
		"auditStatus",
		"reviewer",
		"evidence",
		"tags",
		"metadata",
	},
	ExecutionAdapterRegistrationBoundary = {
		"boundaryId",
		"registryId",
		"registrationId",
		"boundaryKind",
		"boundaryStatus",
		"summary",
		"evidence",
		"tags",
		"metadata",
	},
	ExecutionAdapterRegistrySnapshot = {
		"registrySnapshotId",
		"registryId",
		"snapshotKind",
		"snapshotStatus",
		"providerName",
		"registrationIds",
		"compatibilityIds",
		"evidence",
		"tags",
		"metadata",
	},
	ExecutionAdapterRegistryCompatibility = {
		"compatibilityId",
		"registryId",
		"registrationId",
		"compatibilityKind",
		"compatibilityStatus",
		"targetRuntimeName",
		"evidence",
		"tags",
		"metadata",
	},
}

Types.SchemaFieldCount = {}
for schemaName, fields in pairs(Types.SchemaFields) do
	Types.SchemaFieldCount[schemaName] = #fields
end

Types.RegistryKind = {
	AdapterMetadataRegistry = true,
	CertifiedAdapterCatalog = true,
	CompatibilityRegistry = true,
	BoundaryRegistry = true,
}

Types.RegistryStatus = {
	Declared = true,
	Open = true,
	Certified = true,
	Deferred = true,
	Warning = true,
	Blocked = true,
}

Types.RegistrationKind = {
	AdapterMetadataRegistration = true,
	CapabilityRegistration = true,
	CompatibilityRegistration = true,
	BoundaryRegistration = true,
	AuditRegistration = true,
}

Types.RegistrationStatus = {
	Declared = true,
	Registered = true,
	Certified = true,
	Deferred = true,
	Warning = true,
	Blocked = true,
}

Types.RegistrationBoundaryKind = {
	NoAdapterImplementation = true,
	NoAdapterActivation = true,
	NoAdapterExecution = true,
	NoAssetOperations = true,
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

Types.RegistrationBoundaryStatus = {
	Declared = true,
	Satisfied = true,
	Deferred = true,
	Warning = true,
	Blocked = true,
}

Types.RegistryCompatibilityKind = {
	AdapterRuntimeCompatibility = true,
	AssetExecutionRuntimeCompatibility = true,
	AuthorizationCompatibility = true,
	GovernanceCompatibility = true,
	ContractCompatibility = true,
	SnapshotCompatibility = true,
	DiagnosticsCompatibility = true,
}

Types.RegistryCompatibilityStatus = {
	Declared = true,
	Compatible = true,
	Deferred = true,
	Warning = true,
	Blocked = true,
}

Types.RegistrySnapshotStatus = {
	Declared = true,
	Captured = true,
	Certified = true,
	Deferred = true,
	Warning = true,
	Blocked = true,
}

Types.RegistrationAuditKind = {
	RegistryAudit = true,
	RegistrationAudit = true,
	BoundaryAudit = true,
	CompatibilityAudit = true,
	ProductionAudit = true,
}

Types.RegistrationAuditStatus = {
	Passed = true,
	Failed = true,
	Warning = true,
	Deferred = true,
	Blocked = true,
}

Types.PostureKeys = {
	"assetExecutionAdapterRegistryRuntimePosture",
	"assetExecutionAdapterRegistryValidationPosture",
	"assetExecutionAdapterRegistryRegistrationPosture",
	"assetExecutionAdapterRegistryOwnershipPosture",
	"assetExecutionAdapterRegistryCompatibilityPosture",
	"assetExecutionAdapterRegistryBoundaryPosture",
	"assetExecutionAdapterRegistryAuditPosture",
	"assetExecutionAdapterRegistrySnapshotPosture",
	"assetExecutionAdapterRegistryCertificationPosture",
	"assetExecutionAdapterRegistrySchemaPosture",
	"assetExecutionAdapterRegistryEnumPosture",
	"assetExecutionAdapterRegistryReferencePosture",
	"assetExecutionAdapterRegistryArrayPosture",
	"assetExecutionAdapterRegistryLimitPosture",
	"assetExecutionAdapterRegistryDiagnosticsPosture",
	"assetExecutionAdapterRegistryBootstrapPosture",
	"assetExecutionAdapterRegistryGovernancePosture",
	"assetExecutionAdapterRegistryNoImplementationPosture",
	"assetExecutionAdapterRegistryNoActivationPosture",
	"assetExecutionAdapterRegistryNoExecutionPosture",
	"assetExecutionAdapterRegistryNoOperationPosture",
	"assetExecutionAdapterRegistryNoAuthorityPosture",
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
	"ASSET_EXECUTION_ADAPTER_REGISTRY_RUNTIME.md",
	"ASSET_EXECUTION_ADAPTER_REGISTRY_VALIDATION.md",
	"ASSET_EXECUTION_ADAPTER_REGISTRY_SERIALIZATION.md",
	"ASSET_EXECUTION_ADAPTER_REGISTRY_DIAGNOSTICS.md",
	"ASSET_EXECUTION_ADAPTER_REGISTRY_SNAPSHOTS.md",
	"ASSET_EXECUTION_ADAPTER_REGISTRY_SELF_CHECKS.md",
	"ASSET_EXECUTION_ADAPTER_REGISTRY_AUDIT.md",
	"ASSET_EXECUTION_ADAPTER_REGISTRY_PRODUCTION_REVIEW.md",
}

Types.BootstrapDependencyOrder = {
	"AssetExecutionAdapterCoordinator",
}

Types.GovernanceSnapshotProviders = {
	"assetExecutionAdapterRegistry",
}

Types.Limits = {
	MaxRegistries = 32,
	MaxRegistrations = 240,
	MaxRegistrationBoundaries = 320,
	MaxRegistryCompatibilities = 240,
	MaxRegistrationAudits = 240,
	MaxRegistrySnapshots = 120,
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

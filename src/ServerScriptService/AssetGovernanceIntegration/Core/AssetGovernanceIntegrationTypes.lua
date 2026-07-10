--!strict

local Types = {}

Types.Mode = "ServerAuthoritativeAssetGovernanceIntegrationReadOnlyRuntime"
Types.RuntimeProviderName = "assetGovernanceIntegrationRuntime"

Types.SchemaType = {
	GovernanceChain = "GovernanceChain",
	GovernanceRuntimeNode = "GovernanceRuntimeNode",
	GovernanceReferenceReview = "GovernanceReferenceReview",
	GovernanceIntegrationAudit = "GovernanceIntegrationAudit",
	SystemAssetGovernanceIntegrationSchema = "SystemAssetGovernanceIntegrationSchema",
}

Types.SchemaFields = {
	GovernanceChain = {
		"chainId",
		"chainKind",
		"chainStatus",
		"runtimeNodeIds",
		"referenceReviewIds",
		"auditIds",
		"tags",
		"metadata",
	},
	GovernanceRuntimeNode = {
		"nodeId",
		"chainId",
		"runtimeName",
		"providerName",
		"coordinatorName",
		"expectedOrder",
		"required",
		"nodeStatus",
		"tags",
		"metadata",
	},
	GovernanceReferenceReview = {
		"reviewId",
		"chainId",
		"sourceRuntimeName",
		"targetRuntimeName",
		"referenceKind",
		"referenceStatus",
		"summary",
		"tags",
		"metadata",
	},
	GovernanceIntegrationAudit = {
		"auditId",
		"chainId",
		"auditKind",
		"reviewer",
		"status",
		"findings",
		"tags",
		"metadata",
	},
}

Types.ChainKind = {
	CertifiedAssetGovernanceChain = true,
	RuntimeProviderChain = true,
	ReferenceReadinessChain = true,
	FutureIntegrationChain = true,
}

Types.ChainStatus = {
	Healthy = true,
	Warning = true,
	Blocked = true,
	NeedsReview = true,
	Deferred = true,
}

Types.NodeStatus = {
	Ready = true,
	Missing = true,
	Blocked = true,
	NeedsReview = true,
	Deferred = true,
}

Types.ReferenceKind = {
	ReadinessReference = true,
	DesignContractReference = true,
	AssetReference = true,
	UsagePlanReference = true,
	ChecklistReference = true,
	ApprovalReference = true,
	PermitReference = true,
	GateReference = true,
	RuntimeOrderReference = true,
	FutureReference = true,
}

Types.ReferenceStatus = {
	Present = true,
	Missing = true,
	Passed = true,
	Blocked = true,
	NeedsReview = true,
	Deferred = true,
}

Types.AuditKind = {
	ChainAudit = true,
	ProviderAudit = true,
	ReferenceAudit = true,
	ProductionAudit = true,
	FutureAudit = true,
}

Types.AuditStatus = {
	Passed = true,
	Failed = true,
	Warning = true,
	Deferred = true,
	Blocked = true,
}

Types.RuntimeOrder = {
	{
		runtimeName = "AssetManifest",
		providerName = "assetManifestRuntime",
		coordinatorName = "AssetManifestCoordinator",
	},
	{
		runtimeName = "AssetUsagePlan",
		providerName = "assetUsagePlanRuntime",
		coordinatorName = "AssetUsagePlanCoordinator",
	},
	{
		runtimeName = "AssetReadinessReview",
		providerName = "assetReadinessReviewRuntime",
		coordinatorName = "AssetReadinessReviewCoordinator",
	},
	{
		runtimeName = "AssetApprovalLedger",
		providerName = "assetApprovalLedgerRuntime",
		coordinatorName = "AssetApprovalLedgerCoordinator",
	},
	{
		runtimeName = "AssetExecutionPermit",
		providerName = "assetExecutionPermitRuntime",
		coordinatorName = "AssetExecutionPermitCoordinator",
	},
	{
		runtimeName = "AssetRuntimeGate",
		providerName = "assetRuntimeGateRuntime",
		coordinatorName = "AssetRuntimeGateCoordinator",
	},
	{
		runtimeName = "AssetExecutionBoundaryReview",
		providerName = "assetExecutionBoundaryReviewRuntime",
		coordinatorName = "AssetExecutionBoundaryReviewCoordinator",
	},
	{
		runtimeName = "AssetExecutionDesignContract",
		providerName = "assetExecutionDesignContractRuntime",
		coordinatorName = "AssetExecutionDesignContractCoordinator",
	},
	{
		runtimeName = "AssetExecutionImplementationReadiness",
		providerName = "assetExecutionImplementationReadinessRuntime",
		coordinatorName = "AssetExecutionImplementationReadinessCoordinator",
	},
	{
		runtimeName = "AssetExecutionImplementationContract",
		providerName = "assetExecutionImplementationContractRuntime",
		coordinatorName = "AssetExecutionImplementationContractCoordinator",
	},
}

Types.RuntimeName = {}
Types.ProviderName = {}
Types.CoordinatorName = {}
for order, node in ipairs(Types.RuntimeOrder) do
	Types.RuntimeName[node.runtimeName] = order
	Types.ProviderName[node.providerName] = order
	Types.CoordinatorName[node.coordinatorName] = order
end

Types.Limits = {
	MaxChains = 20,
	MaxRuntimeNodes = 200,
	MaxReferenceReviews = 500,
	MaxAudits = 300,
	MaxValidationFailures = 240,
	MaxSnapshotHistory = 60,
	MaxPayloadDepth = 8,
	MaxPayloadNodes = 450,
	MaxStringLength = 280,
	MaxTags = 32,
	MaxAuditFindings = 40,
	MaxChainChildren = 120,
}

Types.DocumentationFiles = {
	"ASSET_GOVERNANCE_INTEGRATION_RUNTIME.md",
	"ASSET_GOVERNANCE_INTEGRATION_VALIDATION.md",
	"ASSET_GOVERNANCE_INTEGRATION_SERIALIZATION.md",
	"ASSET_GOVERNANCE_INTEGRATION_DIAGNOSTICS.md",
	"ASSET_GOVERNANCE_INTEGRATION_SELF_CHECKS.md",
	"ASSET_GOVERNANCE_INTEGRATION_RUNTIME_LIMITS.md",
	"ASSET_GOVERNANCE_INTEGRATION_AUDIT.md",
	"ASSET_GOVERNANCE_INTEGRATION_PRODUCTION_REVIEW.md",
	"GOVERNANCE_CHAIN_RUNTIME.md",
	"GOVERNANCE_RUNTIME_NODE_RUNTIME.md",
	"GOVERNANCE_REFERENCE_REVIEW_RUNTIME.md",
	"GOVERNANCE_INTEGRATION_AUDIT_RUNTIME.md",
}

Types.BootstrapDependencyOrder = {
	"AssetManifestCoordinator",
	"AssetUsagePlanCoordinator",
	"AssetReadinessReviewCoordinator",
	"AssetApprovalLedgerCoordinator",
	"AssetExecutionPermitCoordinator",
	"AssetRuntimeGateCoordinator",
	"AssetExecutionBoundaryReviewCoordinator",
	"AssetExecutionDesignContractCoordinator",
	"AssetExecutionImplementationReadinessCoordinator",
	"AssetExecutionImplementationContractCoordinator",
}

return Types

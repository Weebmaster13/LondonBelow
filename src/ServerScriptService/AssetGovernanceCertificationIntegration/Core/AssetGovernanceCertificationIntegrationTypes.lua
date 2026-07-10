--!strict

local Types = {}

Types.Mode = "ServerAuthoritativeAssetGovernanceCertificationIntegrationMetadataRuntime"
Types.RuntimeProviderName = "assetGovernanceCertificationIntegrationRuntime"
Types.SnapshotKind = "assetGovernanceCertificationIntegrationRuntimeSnapshot"

Types.SchemaType = {
	GovernanceCertificationIntegration = "GovernanceCertificationIntegration",
	GovernanceCertificationIntegrationChain = "GovernanceCertificationIntegrationChain",
	GovernanceCertificationIntegrationReview = "GovernanceCertificationIntegrationReview",
	GovernanceCertificationIntegrationAudit = "GovernanceCertificationIntegrationAudit",
	SystemAssetGovernanceCertificationIntegrationSchema = "SystemAssetGovernanceCertificationIntegrationSchema",
}

Types.SchemaFields = {
	GovernanceCertificationIntegration = {
		"integrationId",
		"integrationKind",
		"integrationStatus",
		"certificationId",
		"chainId",
		"reviewIds",
		"auditIds",
		"coordinator",
		"integrationVersion",
		"tags",
		"metadata",
	},
	GovernanceCertificationIntegrationChain = {
		"chainId",
		"integrationId",
		"chainKind",
		"chainStatus",
		"runtimeNames",
		"providerNames",
		"readinessIds",
		"required",
		"summary",
		"tags",
		"metadata",
	},
	GovernanceCertificationIntegrationReview = {
		"reviewId",
		"integrationId",
		"runtimeName",
		"providerName",
		"reviewKind",
		"reviewStatus",
		"summary",
		"evidence",
		"tags",
		"metadata",
	},
	GovernanceCertificationIntegrationAudit = {
		"auditId",
		"integrationId",
		"auditKind",
		"reviewer",
		"status",
		"findings",
		"tags",
		"metadata",
	},
}

Types.IntegrationKind = {
	CertificationCoordination = true,
	DependencyCoordination = true,
	ReadinessCoordination = true,
	ProviderCoordination = true,
	BootstrapCoordination = true,
	DocumentationCoordination = true,
	CompatibilityCoordination = true,
	FutureCoordination = true,
}

Types.IntegrationStatus = {
	Draft = true,
	Ready = true,
	Coordinated = true,
	Blocked = true,
	NeedsReview = true,
	Deferred = true,
}

Types.ChainKind = {
	CertifiedGovernanceChain = true,
	CertificationDependencyChain = true,
	CertificationReadinessChain = true,
	ProviderMetadataChain = true,
	BootstrapMetadataChain = true,
	DocumentationMetadataChain = true,
	CompatibilityMetadataChain = true,
	FutureMetadataChain = true,
}

Types.ChainStatus = {
	Ready = true,
	Coordinated = true,
	Warning = true,
	Blocked = true,
	NeedsReview = true,
	Deferred = true,
}

Types.ReviewKind = {
	CertificationMetadataReview = true,
	DependencyMetadataReview = true,
	ReadinessMetadataReview = true,
	ProviderMetadataReview = true,
	BootstrapMetadataReview = true,
	DocumentationMetadataReview = true,
	CompatibilityMetadataReview = true,
	FutureMetadataReview = true,
}

Types.ReviewStatus = {
	Passed = true,
	Warning = true,
	Blocked = true,
	NeedsReview = true,
	Deferred = true,
}

Types.AuditKind = {
	IntegrationAudit = true,
	ChainAudit = true,
	CertificationAudit = true,
	ReadinessAudit = true,
	ProviderAudit = true,
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

Types.CertifiedRuntimeOrder = {
	{
		runtimeName = "AssetManifest",
		providerName = "assetManifestRuntime",
		coordinatorName = "AssetManifestCoordinator",
		readinessId = "assetManifest.integrationReadiness",
	},
	{
		runtimeName = "AssetUsagePlan",
		providerName = "assetUsagePlanRuntime",
		coordinatorName = "AssetUsagePlanCoordinator",
		readinessId = "assetUsagePlan.integrationReadiness",
	},
	{
		runtimeName = "AssetReadinessReview",
		providerName = "assetReadinessReviewRuntime",
		coordinatorName = "AssetReadinessReviewCoordinator",
		readinessId = "assetReadinessReview.integrationReadiness",
	},
	{
		runtimeName = "AssetApprovalLedger",
		providerName = "assetApprovalLedgerRuntime",
		coordinatorName = "AssetApprovalLedgerCoordinator",
		readinessId = "assetApprovalLedger.integrationReadiness",
	},
	{
		runtimeName = "AssetExecutionPermit",
		providerName = "assetExecutionPermitRuntime",
		coordinatorName = "AssetExecutionPermitCoordinator",
		readinessId = "assetExecutionPermit.integrationReadiness",
	},
	{
		runtimeName = "AssetRuntimeGate",
		providerName = "assetRuntimeGateRuntime",
		coordinatorName = "AssetRuntimeGateCoordinator",
		readinessId = "assetRuntimeGate.integrationReadiness",
	},
	{
		runtimeName = "AssetExecutionBoundaryReview",
		providerName = "assetExecutionBoundaryReviewRuntime",
		coordinatorName = "AssetExecutionBoundaryReviewCoordinator",
		readinessId = "assetExecutionBoundaryReview.integrationReadiness",
	},
	{
		runtimeName = "AssetExecutionDesignContract",
		providerName = "assetExecutionDesignContractRuntime",
		coordinatorName = "AssetExecutionDesignContractCoordinator",
		readinessId = "assetExecutionDesignContract.integrationReadiness",
	},
	{
		runtimeName = "AssetExecutionImplementationReadiness",
		providerName = "assetExecutionImplementationReadinessRuntime",
		coordinatorName = "AssetExecutionImplementationReadinessCoordinator",
		readinessId = "assetExecutionImplementationReadiness.integrationReadiness",
	},
	{
		runtimeName = "AssetExecutionImplementationContract",
		providerName = "assetExecutionImplementationContractRuntime",
		coordinatorName = "AssetExecutionImplementationContractCoordinator",
		readinessId = "assetExecutionImplementationContract.integrationReadiness",
	},
	{
		runtimeName = "AssetGovernanceIntegration",
		providerName = "assetGovernanceIntegrationRuntime",
		coordinatorName = "AssetGovernanceIntegrationCoordinator",
		readinessId = "assetGovernanceIntegration.integrationReadiness",
	},
	{
		runtimeName = "AssetGovernanceCertification",
		providerName = "assetGovernanceCertificationRuntime",
		coordinatorName = "AssetGovernanceCertificationCoordinator",
		readinessId = "assetGovernanceCertification.integrationReadiness",
	},
}

Types.RuntimeName = {}
Types.ProviderName = {}
Types.CoordinatorName = {}
Types.ReadinessId = {}
for order, node in ipairs(Types.CertifiedRuntimeOrder) do
	Types.RuntimeName[node.runtimeName] = order
	Types.ProviderName[node.providerName] = order
	Types.CoordinatorName[node.coordinatorName] = order
	Types.ReadinessId[node.readinessId] = order
end

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
	"AssetGovernanceIntegrationCoordinator",
	"AssetGovernanceCertificationCoordinator",
}

Types.DocumentationFiles = {
	"ASSET_GOVERNANCE_CERTIFICATION_INTEGRATION_RUNTIME.md",
	"ASSET_GOVERNANCE_CERTIFICATION_INTEGRATION_VALIDATION.md",
	"ASSET_GOVERNANCE_CERTIFICATION_INTEGRATION_SERIALIZATION.md",
	"ASSET_GOVERNANCE_CERTIFICATION_INTEGRATION_DIAGNOSTICS.md",
	"ASSET_GOVERNANCE_CERTIFICATION_INTEGRATION_SELF_CHECKS.md",
	"ASSET_GOVERNANCE_CERTIFICATION_INTEGRATION_RUNTIME_LIMITS.md",
	"ASSET_GOVERNANCE_CERTIFICATION_INTEGRATION_AUDIT.md",
	"ASSET_GOVERNANCE_CERTIFICATION_INTEGRATION_PRODUCTION_REVIEW.md",
	"GOVERNANCE_CERTIFICATION_INTEGRATION_RUNTIME.md",
	"GOVERNANCE_CERTIFICATION_INTEGRATION_CHAIN_RUNTIME.md",
	"GOVERNANCE_CERTIFICATION_INTEGRATION_REVIEW_RUNTIME.md",
	"GOVERNANCE_CERTIFICATION_INTEGRATION_AUDIT_RUNTIME.md",
}

Types.PostureKeys = {
	"certificationIntegrationCoordinationPosture",
	"copiedCertificationMetadataPosture",
	"copiedDependencyMetadataPosture",
	"copiedReadinessMetadataPosture",
	"copiedProviderMetadataPosture",
	"copiedBootstrapMetadataPosture",
	"copiedDocumentationMetadataPosture",
	"copiedCompatibilityMetadataPosture",
	"certifiedGovernanceChain",
}

Types.Limits = {
	MaxIntegrations = 40,
	MaxChains = 120,
	MaxReviews = 530,
	MaxAudits = 300,
	MaxValidationFailures = 240,
	MaxSnapshotHistory = 60,
	MaxPayloadDepth = 8,
	MaxPayloadNodes = 450,
	MaxStringLength = 280,
	MaxTags = 32,
	MaxAuditFindings = 40,
	MaxReviewEvidence = 40,
	MaxIntegrationChildren = 180,
	MaxChainEntries = 120,
}

return Types

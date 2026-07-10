--!strict

local Types = {}

Types.Mode = "ServerAuthoritativeAssetGovernanceCertificationMetadataRuntime"
Types.RuntimeProviderName = "assetGovernanceCertificationRuntime"

Types.SchemaType = {
	GovernanceCertification = "GovernanceCertification",
	GovernanceCertificationRequirement = "GovernanceCertificationRequirement",
	GovernanceCertificationResult = "GovernanceCertificationResult",
	GovernanceCertificationAudit = "GovernanceCertificationAudit",
	SystemAssetGovernanceCertificationSchema = "SystemAssetGovernanceCertificationSchema",
}

Types.SchemaFields = {
	GovernanceCertification = {
		"certificationId",
		"certificationKind",
		"certificationStatus",
		"chainId",
		"requirementIds",
		"resultIds",
		"auditIds",
		"reviewer",
		"certificationVersion",
		"tags",
		"metadata",
	},
	GovernanceCertificationRequirement = {
		"requirementId",
		"certificationId",
		"requirementKind",
		"required",
		"status",
		"summary",
		"tags",
		"metadata",
	},
	GovernanceCertificationResult = {
		"resultId",
		"certificationId",
		"resultKind",
		"resultStatus",
		"message",
		"evidence",
		"tags",
		"metadata",
	},
	GovernanceCertificationAudit = {
		"auditId",
		"certificationId",
		"auditKind",
		"reviewer",
		"status",
		"findings",
		"tags",
		"metadata",
	},
}

Types.CertificationKind = {
	GovernanceChainCertification = true,
	ProviderCertification = true,
	DependencyCertification = true,
	BootstrapCertification = true,
	DocumentationCertification = true,
	FutureCertification = true,
}

Types.CertificationStatus = {
	Draft = true,
	Eligible = true,
	Certified = true,
	Blocked = true,
	NeedsReview = true,
	Deferred = true,
}

Types.RequirementKind = {
	RuntimePresenceRequirement = true,
	ProviderConsistencyRequirement = true,
	DependencyOrderingRequirement = true,
	GovernanceContractRequirement = true,
	DiagnosticsCompatibilityRequirement = true,
	SnapshotCompatibilityRequirement = true,
	BootstrapOrderingRequirement = true,
	DocumentationCompletenessRequirement = true,
	IntegrationReadinessRequirement = true,
	FutureRequirement = true,
}

Types.RequirementStatus = {
	Passed = true,
	Failed = true,
	Warning = true,
	Blocked = true,
	NeedsReview = true,
	Deferred = true,
}

Types.ResultKind = {
	EligibilityResult = true,
	ProviderResult = true,
	DependencyResult = true,
	GovernanceResult = true,
	DiagnosticsResult = true,
	SnapshotResult = true,
	BootstrapResult = true,
	DocumentationResult = true,
	IntegrationResult = true,
	FutureResult = true,
}

Types.ResultStatus = {
	Passed = true,
	Failed = true,
	Warning = true,
	Blocked = true,
	NeedsReview = true,
	Deferred = true,
}

Types.AuditKind = {
	CertificationAudit = true,
	ProviderAudit = true,
	DependencyAudit = true,
	GovernanceAudit = true,
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
	{
		runtimeName = "AssetGovernanceIntegration",
		providerName = "assetGovernanceIntegrationRuntime",
		coordinatorName = "AssetGovernanceIntegrationCoordinator",
	},
}

Types.RuntimeName = {}
Types.ProviderName = {}
Types.CoordinatorName = {}
for order, node in ipairs(Types.CertifiedRuntimeOrder) do
	Types.RuntimeName[node.runtimeName] = order
	Types.ProviderName[node.providerName] = order
	Types.CoordinatorName[node.coordinatorName] = order
end

Types.DocumentationFiles = {
	"ASSET_GOVERNANCE_CERTIFICATION_RUNTIME.md",
	"ASSET_GOVERNANCE_CERTIFICATION_VALIDATION.md",
	"ASSET_GOVERNANCE_CERTIFICATION_SERIALIZATION.md",
	"ASSET_GOVERNANCE_CERTIFICATION_DIAGNOSTICS.md",
	"ASSET_GOVERNANCE_CERTIFICATION_SELF_CHECKS.md",
	"ASSET_GOVERNANCE_CERTIFICATION_RUNTIME_LIMITS.md",
	"ASSET_GOVERNANCE_CERTIFICATION_AUDIT.md",
	"ASSET_GOVERNANCE_CERTIFICATION_PRODUCTION_REVIEW.md",
	"GOVERNANCE_CERTIFICATION_RUNTIME.md",
	"GOVERNANCE_CERTIFICATION_REQUIREMENT_RUNTIME.md",
	"GOVERNANCE_CERTIFICATION_RESULT_RUNTIME.md",
	"GOVERNANCE_CERTIFICATION_AUDIT_RUNTIME.md",
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
	"AssetGovernanceIntegrationCoordinator",
}

Types.Limits = {
	MaxCertifications = 60,
	MaxRequirements = 600,
	MaxResults = 600,
	MaxAudits = 300,
	MaxValidationFailures = 240,
	MaxSnapshotHistory = 60,
	MaxPayloadDepth = 8,
	MaxPayloadNodes = 450,
	MaxStringLength = 280,
	MaxTags = 32,
	MaxAuditFindings = 40,
	MaxResultEvidence = 40,
	MaxCertificationChildren = 180,
}

return Types

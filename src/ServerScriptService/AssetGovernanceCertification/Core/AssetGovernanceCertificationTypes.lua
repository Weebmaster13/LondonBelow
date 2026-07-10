--!strict

local Types = {}

Types.Mode = "ServerAuthoritativeAssetGovernanceCertificationMetadataRuntime"
Types.RuntimeProviderName = "assetGovernanceCertificationRuntime"
Types.SnapshotKind = "assetGovernanceCertificationRuntimeSnapshot"

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

Types.IntegrationReadinessKind = {
	DependencyChainReadiness = true,
	BootstrapReadiness = true,
	GovernanceReadiness = true,
	ProviderReadiness = true,
	SnapshotProviderReadiness = true,
	DiagnosticsReadiness = true,
	DocumentationReadiness = true,
	RuntimeCompatibilityReadiness = true,
	CertificationScopeReadiness = true,
	FutureIntegrationReadiness = true,
}

Types.IntegrationReadinessState = {
	Ready = true,
	NeedsReview = true,
	Blocked = true,
	Deferred = true,
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
	"ASSET_GOVERNANCE_CERTIFICATION_INTEGRATION_READINESS.md",
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

Types.CertificationRuntimeNode = {
	runtimeName = "AssetGovernanceCertification",
	providerName = Types.RuntimeProviderName,
	coordinatorName = "AssetGovernanceCertificationCoordinator",
	snapshotProvider = Types.RuntimeProviderName,
	diagnosticsProvider = "AssetGovernanceCertificationCoordinator.inspect",
	bootstrapAfter = "AssetGovernanceIntegrationCoordinator",
	documentationFile = "ASSET_GOVERNANCE_CERTIFICATION_INTEGRATION_READINESS.md",
}

Types.IntegrationReadinessDeclarationFields = {
	"readinessId",
	"readinessKind",
	"readinessState",
	"runtimeName",
	"providerName",
	"coordinatorName",
	"bootstrapAfter",
	"snapshotProvider",
	"diagnosticsProvider",
	"documentationFile",
	"required",
	"summary",
	"tags",
	"metadata",
}

Types.IntegrationReadinessDeclarations = {
	{
		readinessId = "assetManifest.integrationReadiness",
		readinessKind = "DependencyChainReadiness",
		readinessState = "Ready",
		runtimeName = "AssetManifest",
		providerName = "assetManifestRuntime",
		coordinatorName = "AssetManifestCoordinator",
		bootstrapAfter = nil,
		snapshotProvider = "assetManifestRuntime",
		diagnosticsProvider = "AssetManifestCoordinator.inspect",
		documentationFile = "ASSET_MANIFEST_RUNTIME.md",
		required = true,
		summary = "Asset Manifest begins the certified asset governance chain.",
		tags = { "asset-governance", "integration-readiness" },
	},
	{
		readinessId = "assetUsagePlan.integrationReadiness",
		readinessKind = "DependencyChainReadiness",
		readinessState = "Ready",
		runtimeName = "AssetUsagePlan",
		providerName = "assetUsagePlanRuntime",
		coordinatorName = "AssetUsagePlanCoordinator",
		bootstrapAfter = "AssetManifestCoordinator",
		snapshotProvider = "assetUsagePlanRuntime",
		diagnosticsProvider = "AssetUsagePlanCoordinator.inspect",
		documentationFile = "ASSET_USAGE_PLAN_RUNTIME.md",
		required = true,
		summary = "Asset Usage Plan follows Asset Manifest in the certified chain.",
		tags = { "asset-governance", "integration-readiness" },
	},
	{
		readinessId = "assetReadinessReview.integrationReadiness",
		readinessKind = "DependencyChainReadiness",
		readinessState = "Ready",
		runtimeName = "AssetReadinessReview",
		providerName = "assetReadinessReviewRuntime",
		coordinatorName = "AssetReadinessReviewCoordinator",
		bootstrapAfter = "AssetUsagePlanCoordinator",
		snapshotProvider = "assetReadinessReviewRuntime",
		diagnosticsProvider = "AssetReadinessReviewCoordinator.inspect",
		documentationFile = "ASSET_READINESS_REVIEW_RUNTIME.md",
		required = true,
		summary = "Asset Readiness Review follows Asset Usage Plan in the certified chain.",
		tags = { "asset-governance", "integration-readiness" },
	},
	{
		readinessId = "assetApprovalLedger.integrationReadiness",
		readinessKind = "DependencyChainReadiness",
		readinessState = "Ready",
		runtimeName = "AssetApprovalLedger",
		providerName = "assetApprovalLedgerRuntime",
		coordinatorName = "AssetApprovalLedgerCoordinator",
		bootstrapAfter = "AssetReadinessReviewCoordinator",
		snapshotProvider = "assetApprovalLedgerRuntime",
		diagnosticsProvider = "AssetApprovalLedgerCoordinator.inspect",
		documentationFile = "ASSET_APPROVAL_LEDGER_RUNTIME.md",
		required = true,
		summary = "Asset Approval Ledger follows Asset Readiness Review in the certified chain.",
		tags = { "asset-governance", "integration-readiness" },
	},
	{
		readinessId = "assetExecutionPermit.integrationReadiness",
		readinessKind = "DependencyChainReadiness",
		readinessState = "Ready",
		runtimeName = "AssetExecutionPermit",
		providerName = "assetExecutionPermitRuntime",
		coordinatorName = "AssetExecutionPermitCoordinator",
		bootstrapAfter = "AssetApprovalLedgerCoordinator",
		snapshotProvider = "assetExecutionPermitRuntime",
		diagnosticsProvider = "AssetExecutionPermitCoordinator.inspect",
		documentationFile = "ASSET_EXECUTION_PERMIT_RUNTIME.md",
		required = true,
		summary = "Asset Execution Permit follows Asset Approval Ledger in the certified chain.",
		tags = { "asset-governance", "integration-readiness" },
	},
	{
		readinessId = "assetRuntimeGate.integrationReadiness",
		readinessKind = "DependencyChainReadiness",
		readinessState = "Ready",
		runtimeName = "AssetRuntimeGate",
		providerName = "assetRuntimeGateRuntime",
		coordinatorName = "AssetRuntimeGateCoordinator",
		bootstrapAfter = "AssetExecutionPermitCoordinator",
		snapshotProvider = "assetRuntimeGateRuntime",
		diagnosticsProvider = "AssetRuntimeGateCoordinator.inspect",
		documentationFile = "ASSET_RUNTIME_GATE_RUNTIME.md",
		required = true,
		summary = "Asset Runtime Gate follows Asset Execution Permit in the certified chain.",
		tags = { "asset-governance", "integration-readiness" },
	},
	{
		readinessId = "assetExecutionBoundaryReview.integrationReadiness",
		readinessKind = "DependencyChainReadiness",
		readinessState = "Ready",
		runtimeName = "AssetExecutionBoundaryReview",
		providerName = "assetExecutionBoundaryReviewRuntime",
		coordinatorName = "AssetExecutionBoundaryReviewCoordinator",
		bootstrapAfter = "AssetRuntimeGateCoordinator",
		snapshotProvider = "assetExecutionBoundaryReviewRuntime",
		diagnosticsProvider = "AssetExecutionBoundaryReviewCoordinator.inspect",
		documentationFile = "ASSET_EXECUTION_BOUNDARY_REVIEW_RUNTIME.md",
		required = true,
		summary = "Asset Execution Boundary Review follows Asset Runtime Gate in the certified chain.",
		tags = { "asset-governance", "integration-readiness" },
	},
	{
		readinessId = "assetExecutionDesignContract.integrationReadiness",
		readinessKind = "DependencyChainReadiness",
		readinessState = "Ready",
		runtimeName = "AssetExecutionDesignContract",
		providerName = "assetExecutionDesignContractRuntime",
		coordinatorName = "AssetExecutionDesignContractCoordinator",
		bootstrapAfter = "AssetExecutionBoundaryReviewCoordinator",
		snapshotProvider = "assetExecutionDesignContractRuntime",
		diagnosticsProvider = "AssetExecutionDesignContractCoordinator.inspect",
		documentationFile = "ASSET_EXECUTION_DESIGN_CONTRACT_RUNTIME.md",
		required = true,
		summary = "Asset Execution Design Contract follows Asset Execution Boundary Review in the certified chain.",
		tags = { "asset-governance", "integration-readiness" },
	},
	{
		readinessId = "assetExecutionImplementationReadiness.integrationReadiness",
		readinessKind = "DependencyChainReadiness",
		readinessState = "Ready",
		runtimeName = "AssetExecutionImplementationReadiness",
		providerName = "assetExecutionImplementationReadinessRuntime",
		coordinatorName = "AssetExecutionImplementationReadinessCoordinator",
		bootstrapAfter = "AssetExecutionDesignContractCoordinator",
		snapshotProvider = "assetExecutionImplementationReadinessRuntime",
		diagnosticsProvider = "AssetExecutionImplementationReadinessCoordinator.inspect",
		documentationFile = "ASSET_EXECUTION_IMPLEMENTATION_READINESS_RUNTIME.md",
		required = true,
		summary = "Asset Execution Implementation Readiness follows Asset Execution Design Contract in the certified chain.",
		tags = { "asset-governance", "integration-readiness" },
	},
	{
		readinessId = "assetExecutionImplementationContract.integrationReadiness",
		readinessKind = "DependencyChainReadiness",
		readinessState = "Ready",
		runtimeName = "AssetExecutionImplementationContract",
		providerName = "assetExecutionImplementationContractRuntime",
		coordinatorName = "AssetExecutionImplementationContractCoordinator",
		bootstrapAfter = "AssetExecutionImplementationReadinessCoordinator",
		snapshotProvider = "assetExecutionImplementationContractRuntime",
		diagnosticsProvider = "AssetExecutionImplementationContractCoordinator.inspect",
		documentationFile = "ASSET_EXECUTION_IMPLEMENTATION_CONTRACT_RUNTIME.md",
		required = true,
		summary = "Asset Execution Implementation Contract follows Asset Execution Implementation Readiness in the certified chain.",
		tags = { "asset-governance", "integration-readiness" },
	},
	{
		readinessId = "assetGovernanceIntegration.integrationReadiness",
		readinessKind = "DependencyChainReadiness",
		readinessState = "Ready",
		runtimeName = "AssetGovernanceIntegration",
		providerName = "assetGovernanceIntegrationRuntime",
		coordinatorName = "AssetGovernanceIntegrationCoordinator",
		bootstrapAfter = "AssetExecutionImplementationContractCoordinator",
		snapshotProvider = "assetGovernanceIntegrationRuntime",
		diagnosticsProvider = "AssetGovernanceIntegrationCoordinator.inspect",
		documentationFile = "ASSET_GOVERNANCE_INTEGRATION_RUNTIME.md",
		required = true,
		summary = "Asset Governance Integration closes the upstream certified chain.",
		tags = { "asset-governance", "integration-readiness" },
	},
	{
		readinessId = "assetGovernanceCertification.integrationReadiness",
		readinessKind = "FutureIntegrationReadiness",
		readinessState = "Ready",
		runtimeName = Types.CertificationRuntimeNode.runtimeName,
		providerName = Types.CertificationRuntimeNode.providerName,
		coordinatorName = Types.CertificationRuntimeNode.coordinatorName,
		bootstrapAfter = Types.CertificationRuntimeNode.bootstrapAfter,
		snapshotProvider = Types.CertificationRuntimeNode.snapshotProvider,
		diagnosticsProvider = Types.CertificationRuntimeNode.diagnosticsProvider,
		documentationFile = Types.CertificationRuntimeNode.documentationFile,
		required = true,
		summary = "Asset Governance Certification is ready for future subsystem-wide inspection without gaining execution authority.",
		tags = { "asset-governance", "integration-readiness", "certification" },
	},
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

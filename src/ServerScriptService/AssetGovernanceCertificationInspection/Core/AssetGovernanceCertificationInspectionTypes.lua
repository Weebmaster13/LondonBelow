--!strict

local Types = {}

Types.Mode = "ServerAuthoritativeAssetGovernanceCertificationInspectionMetadataRuntime"
Types.RuntimeProviderName = "assetGovernanceCertificationInspectionRuntime"
Types.SnapshotKind = "assetGovernanceCertificationInspectionRuntimeSnapshot"

Types.SchemaType = {
	GovernanceInspection = "GovernanceInspection",
	GovernanceInspectionObservation = "GovernanceInspectionObservation",
	GovernanceInspectionFinding = "GovernanceInspectionFinding",
	GovernanceInspectionAudit = "GovernanceInspectionAudit",
	SystemAssetGovernanceCertificationInspectionSchema = "SystemAssetGovernanceCertificationInspectionSchema",
}

Types.SchemaFields = {
	GovernanceInspection = {
		"inspectionId",
		"inspectionKind",
		"inspectionStatus",
		"integrationId",
		"certificationId",
		"coverageId",
		"observationIds",
		"findingIds",
		"auditIds",
		"inspector",
		"inspectionVersion",
		"tags",
		"metadata",
	},
	GovernanceInspectionObservation = {
		"observationId",
		"inspectionId",
		"runtimeName",
		"providerName",
		"snapshotProviderName",
		"observationKind",
		"observationStatus",
		"health",
		"evidence",
		"tags",
		"metadata",
	},
	GovernanceInspectionFinding = {
		"findingId",
		"inspectionId",
		"observationId",
		"runtimeName",
		"providerName",
		"snapshotProviderName",
		"findingKind",
		"findingSeverity",
		"findingStatus",
		"summary",
		"evidence",
		"tags",
		"metadata",
	},
	GovernanceInspectionAudit = {
		"auditId",
		"inspectionId",
		"findingIds",
		"auditKind",
		"reviewer",
		"status",
		"findings",
		"tags",
		"metadata",
	},
}

Types.InspectionKind = {
	CertificationHealthInspection = true,
	ProviderHealthInspection = true,
	SnapshotHealthInspection = true,
	DiagnosticsHealthInspection = true,
	BootstrapHealthInspection = true,
	GovernanceHealthInspection = true,
	DocumentationHealthInspection = true,
	RuntimeCompatibilityInspection = true,
	FutureHealthInspection = true,
}

Types.InspectionStatus = {
	Draft = true,
	Ready = true,
	Inspecting = true,
	Passed = true,
	Warning = true,
	Blocked = true,
	Deferred = true,
}

Types.ObservationKind = {
	CopiedDiagnosticsObservation = true,
	CopiedSnapshotObservation = true,
	ProviderPostureObservation = true,
	SnapshotPostureObservation = true,
	BootstrapPostureObservation = true,
	GovernancePostureObservation = true,
	DocumentationPostureObservation = true,
	RuntimeCompatibilityObservation = true,
	FutureObservation = true,
}

Types.ObservationStatus = {
	Observed = true,
	Consistent = true,
	Inconsistent = true,
	Missing = true,
	Warning = true,
	Deferred = true,
}

Types.FindingKind = {
	ProviderMismatch = true,
	SnapshotMismatch = true,
	DiagnosticsMismatch = true,
	BootstrapMismatch = true,
	GovernanceMismatch = true,
	DocumentationMismatch = true,
	RuntimeCompatibilityMismatch = true,
	UnsafeEvidence = true,
	FutureFinding = true,
}

Types.FindingSeverity = {
	Info = true,
	Warning = true,
	Error = true,
	Critical = true,
	Deferred = true,
}

Types.FindingStatus = {
	Reported = true,
	Confirmed = true,
	Dismissed = true,
	NeedsReview = true,
	Deferred = true,
}

Types.AuditKind = {
	InspectionAudit = true,
	ObservationAudit = true,
	FindingAudit = true,
	CoverageAudit = true,
	ProviderAudit = true,
	SnapshotAudit = true,
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

Types.Health = {
	Healthy = true,
	Warning = true,
	Unhealthy = true,
	Missing = true,
	Unknown = true,
	Deferred = true,
}

Types.ReadinessKind = {
	IntegrationCompatibility = true,
	RuntimeCompatibility = true,
	ProviderCompatibility = true,
	SnapshotCompatibility = true,
	BootstrapCompatibility = true,
	GovernanceCompatibility = true,
	DocumentationCompatibility = true,
	InspectionCoverageCompatibility = true,
}

Types.ReadinessStatus = {
	Declared = true,
	Compatible = true,
	Ready = true,
	Warning = true,
	Deferred = true,
}

Types.CertifiedRuntimeOrder = {
	{
		runtimeName = "AssetManifest",
		providerName = "assetManifestRuntime",
		snapshotProviderName = "assetManifestRuntime",
		coordinatorName = "AssetManifestCoordinator",
	},
	{
		runtimeName = "AssetUsagePlan",
		providerName = "assetUsagePlanRuntime",
		snapshotProviderName = "assetUsagePlanRuntime",
		coordinatorName = "AssetUsagePlanCoordinator",
	},
	{
		runtimeName = "AssetReadinessReview",
		providerName = "assetReadinessReviewRuntime",
		snapshotProviderName = "assetReadinessReviewRuntime",
		coordinatorName = "AssetReadinessReviewCoordinator",
	},
	{
		runtimeName = "AssetApprovalLedger",
		providerName = "assetApprovalLedgerRuntime",
		snapshotProviderName = "assetApprovalLedgerRuntime",
		coordinatorName = "AssetApprovalLedgerCoordinator",
	},
	{
		runtimeName = "AssetExecutionPermit",
		providerName = "assetExecutionPermitRuntime",
		snapshotProviderName = "assetExecutionPermitRuntime",
		coordinatorName = "AssetExecutionPermitCoordinator",
	},
	{
		runtimeName = "AssetRuntimeGate",
		providerName = "assetRuntimeGateRuntime",
		snapshotProviderName = "assetRuntimeGateRuntime",
		coordinatorName = "AssetRuntimeGateCoordinator",
	},
	{
		runtimeName = "AssetExecutionBoundaryReview",
		providerName = "assetExecutionBoundaryReviewRuntime",
		snapshotProviderName = "assetExecutionBoundaryReviewRuntime",
		coordinatorName = "AssetExecutionBoundaryReviewCoordinator",
	},
	{
		runtimeName = "AssetExecutionDesignContract",
		providerName = "assetExecutionDesignContractRuntime",
		snapshotProviderName = "assetExecutionDesignContractRuntime",
		coordinatorName = "AssetExecutionDesignContractCoordinator",
	},
	{
		runtimeName = "AssetExecutionImplementationReadiness",
		providerName = "assetExecutionImplementationReadinessRuntime",
		snapshotProviderName = "assetExecutionImplementationReadinessRuntime",
		coordinatorName = "AssetExecutionImplementationReadinessCoordinator",
	},
	{
		runtimeName = "AssetExecutionImplementationContract",
		providerName = "assetExecutionImplementationContractRuntime",
		snapshotProviderName = "assetExecutionImplementationContractRuntime",
		coordinatorName = "AssetExecutionImplementationContractCoordinator",
	},
	{
		runtimeName = "AssetGovernanceIntegration",
		providerName = "assetGovernanceIntegrationRuntime",
		snapshotProviderName = "assetGovernanceIntegrationRuntime",
		coordinatorName = "AssetGovernanceIntegrationCoordinator",
	},
	{
		runtimeName = "AssetGovernanceCertification",
		providerName = "assetGovernanceCertificationRuntime",
		snapshotProviderName = "assetGovernanceCertificationRuntime",
		coordinatorName = "AssetGovernanceCertificationCoordinator",
	},
	{
		runtimeName = "AssetGovernanceCertificationIntegration",
		providerName = "assetGovernanceCertificationIntegrationRuntime",
		snapshotProviderName = "assetGovernanceCertificationIntegrationRuntime",
		coordinatorName = "AssetGovernanceCertificationIntegrationCoordinator",
	},
}

Types.RuntimeName = {}
Types.ProviderName = {}
Types.SnapshotProviderName = {}
Types.CoordinatorName = {}
for order, node in ipairs(Types.CertifiedRuntimeOrder) do
	Types.RuntimeName[node.runtimeName] = order
	Types.ProviderName[node.providerName] = order
	Types.SnapshotProviderName[node.snapshotProviderName] = order
	Types.CoordinatorName[node.coordinatorName] = order
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
	"AssetGovernanceCertificationIntegrationCoordinator",
}

Types.DocumentationFiles = {
	"ASSET_GOVERNANCE_CERTIFICATION_INSPECTION_INTEGRATION_READINESS.md",
	"ASSET_GOVERNANCE_CERTIFICATION_INSPECTION_RUNTIME.md",
	"ASSET_GOVERNANCE_CERTIFICATION_INSPECTION_VALIDATION.md",
	"ASSET_GOVERNANCE_CERTIFICATION_INSPECTION_SERIALIZATION.md",
	"ASSET_GOVERNANCE_CERTIFICATION_INSPECTION_DIAGNOSTICS.md",
	"ASSET_GOVERNANCE_CERTIFICATION_INSPECTION_SELF_CHECKS.md",
	"ASSET_GOVERNANCE_CERTIFICATION_INSPECTION_RUNTIME_LIMITS.md",
	"ASSET_GOVERNANCE_CERTIFICATION_INSPECTION_AUDIT.md",
	"ASSET_GOVERNANCE_CERTIFICATION_INSPECTION_PRODUCTION_REVIEW.md",
	"GOVERNANCE_INSPECTION_RUNTIME.md",
	"GOVERNANCE_INSPECTION_OBSERVATION_RUNTIME.md",
	"GOVERNANCE_INSPECTION_FINDING_RUNTIME.md",
	"GOVERNANCE_INSPECTION_AUDIT_RUNTIME.md",
}

Types.IntegrationReadinessDeclarations = {
	{
		readinessId = "inspection.integration.assetUsagePlan",
		readinessKind = "IntegrationCompatibility",
		readinessStatus = "Ready",
		runtimeName = "AssetUsagePlan",
		providerName = "assetUsagePlanRuntime",
		snapshotProviderName = "assetUsagePlanRuntime",
		coordinatorName = "AssetUsagePlanCoordinator",
		diagnosticsProviderName = "AssetUsagePlanCoordinator.inspect",
		documentationReference = "ASSET_USAGE_PLAN_RUNTIME.md",
		metadata = { copiedMetadataOnly = true },
	},
	{
		readinessId = "inspection.integration.assetReadinessReview",
		readinessKind = "IntegrationCompatibility",
		readinessStatus = "Ready",
		runtimeName = "AssetReadinessReview",
		providerName = "assetReadinessReviewRuntime",
		snapshotProviderName = "assetReadinessReviewRuntime",
		coordinatorName = "AssetReadinessReviewCoordinator",
		diagnosticsProviderName = "AssetReadinessReviewCoordinator.inspect",
		documentationReference = "ASSET_READINESS_REVIEW_RUNTIME.md",
		metadata = { copiedMetadataOnly = true },
	},
	{
		readinessId = "inspection.integration.assetApprovalLedger",
		readinessKind = "IntegrationCompatibility",
		readinessStatus = "Ready",
		runtimeName = "AssetApprovalLedger",
		providerName = "assetApprovalLedgerRuntime",
		snapshotProviderName = "assetApprovalLedgerRuntime",
		coordinatorName = "AssetApprovalLedgerCoordinator",
		diagnosticsProviderName = "AssetApprovalLedgerCoordinator.inspect",
		documentationReference = "ASSET_APPROVAL_LEDGER_RUNTIME.md",
		metadata = { copiedMetadataOnly = true },
	},
	{
		readinessId = "inspection.integration.assetExecutionPermit",
		readinessKind = "IntegrationCompatibility",
		readinessStatus = "Ready",
		runtimeName = "AssetExecutionPermit",
		providerName = "assetExecutionPermitRuntime",
		snapshotProviderName = "assetExecutionPermitRuntime",
		coordinatorName = "AssetExecutionPermitCoordinator",
		diagnosticsProviderName = "AssetExecutionPermitCoordinator.inspect",
		documentationReference = "ASSET_EXECUTION_PERMIT_RUNTIME.md",
		metadata = { copiedMetadataOnly = true },
	},
	{
		readinessId = "inspection.integration.assetRuntimeGate",
		readinessKind = "IntegrationCompatibility",
		readinessStatus = "Ready",
		runtimeName = "AssetRuntimeGate",
		providerName = "assetRuntimeGateRuntime",
		snapshotProviderName = "assetRuntimeGateRuntime",
		coordinatorName = "AssetRuntimeGateCoordinator",
		diagnosticsProviderName = "AssetRuntimeGateCoordinator.inspect",
		documentationReference = "ASSET_RUNTIME_GATE_RUNTIME.md",
		metadata = { copiedMetadataOnly = true },
	},
	{
		readinessId = "inspection.integration.assetExecutionBoundaryReview",
		readinessKind = "IntegrationCompatibility",
		readinessStatus = "Ready",
		runtimeName = "AssetExecutionBoundaryReview",
		providerName = "assetExecutionBoundaryReviewRuntime",
		snapshotProviderName = "assetExecutionBoundaryReviewRuntime",
		coordinatorName = "AssetExecutionBoundaryReviewCoordinator",
		diagnosticsProviderName = "AssetExecutionBoundaryReviewCoordinator.inspect",
		documentationReference = "ASSET_EXECUTION_BOUNDARY_REVIEW_RUNTIME.md",
		metadata = { copiedMetadataOnly = true },
	},
	{
		readinessId = "inspection.integration.assetExecutionDesignContract",
		readinessKind = "IntegrationCompatibility",
		readinessStatus = "Ready",
		runtimeName = "AssetExecutionDesignContract",
		providerName = "assetExecutionDesignContractRuntime",
		snapshotProviderName = "assetExecutionDesignContractRuntime",
		coordinatorName = "AssetExecutionDesignContractCoordinator",
		diagnosticsProviderName = "AssetExecutionDesignContractCoordinator.inspect",
		documentationReference = "ASSET_EXECUTION_DESIGN_CONTRACT_RUNTIME.md",
		metadata = { copiedMetadataOnly = true },
	},
	{
		readinessId = "inspection.integration.assetExecutionImplementationReadiness",
		readinessKind = "IntegrationCompatibility",
		readinessStatus = "Ready",
		runtimeName = "AssetExecutionImplementationReadiness",
		providerName = "assetExecutionImplementationReadinessRuntime",
		snapshotProviderName = "assetExecutionImplementationReadinessRuntime",
		coordinatorName = "AssetExecutionImplementationReadinessCoordinator",
		diagnosticsProviderName = "AssetExecutionImplementationReadinessCoordinator.inspect",
		documentationReference = "ASSET_EXECUTION_IMPLEMENTATION_READINESS_RUNTIME.md",
		metadata = { copiedMetadataOnly = true },
	},
	{
		readinessId = "inspection.integration.assetExecutionImplementationContract",
		readinessKind = "IntegrationCompatibility",
		readinessStatus = "Ready",
		runtimeName = "AssetExecutionImplementationContract",
		providerName = "assetExecutionImplementationContractRuntime",
		snapshotProviderName = "assetExecutionImplementationContractRuntime",
		coordinatorName = "AssetExecutionImplementationContractCoordinator",
		diagnosticsProviderName = "AssetExecutionImplementationContractCoordinator.inspect",
		documentationReference = "ASSET_EXECUTION_IMPLEMENTATION_CONTRACT_RUNTIME.md",
		metadata = { copiedMetadataOnly = true },
	},
	{
		readinessId = "inspection.integration.assetGovernanceIntegration",
		readinessKind = "IntegrationCompatibility",
		readinessStatus = "Ready",
		runtimeName = "AssetGovernanceIntegration",
		providerName = "assetGovernanceIntegrationRuntime",
		snapshotProviderName = "assetGovernanceIntegrationRuntime",
		coordinatorName = "AssetGovernanceIntegrationCoordinator",
		diagnosticsProviderName = "AssetGovernanceIntegrationCoordinator.inspect",
		documentationReference = "ASSET_GOVERNANCE_INTEGRATION_RUNTIME.md",
		metadata = { copiedMetadataOnly = true },
	},
	{
		readinessId = "inspection.integration.assetGovernanceCertification",
		readinessKind = "IntegrationCompatibility",
		readinessStatus = "Ready",
		runtimeName = "AssetGovernanceCertification",
		providerName = "assetGovernanceCertificationRuntime",
		snapshotProviderName = "assetGovernanceCertificationRuntime",
		coordinatorName = "AssetGovernanceCertificationCoordinator",
		diagnosticsProviderName = "AssetGovernanceCertificationCoordinator.inspect",
		documentationReference = "ASSET_GOVERNANCE_CERTIFICATION_RUNTIME.md",
		metadata = { copiedMetadataOnly = true },
	},
	{
		readinessId = "inspection.integration.assetGovernanceCertificationIntegration",
		readinessKind = "IntegrationCompatibility",
		readinessStatus = "Ready",
		runtimeName = "AssetGovernanceCertificationIntegration",
		providerName = "assetGovernanceCertificationIntegrationRuntime",
		snapshotProviderName = "assetGovernanceCertificationIntegrationRuntime",
		coordinatorName = "AssetGovernanceCertificationIntegrationCoordinator",
		diagnosticsProviderName = "AssetGovernanceCertificationIntegrationCoordinator.inspect",
		documentationReference = "ASSET_GOVERNANCE_CERTIFICATION_INTEGRATION_RUNTIME.md",
		metadata = { copiedMetadataOnly = true },
	},
}

Types.PostureKeys = {
	"integrationReadinessPosture",
	"inspectionPosture",
	"observationPosture",
	"findingPosture",
	"auditPosture",
	"providerPosture",
	"snapshotPosture",
	"runtimeCompatibilityPosture",
	"providerCompatibilityPosture",
	"snapshotCompatibilityPosture",
	"bootstrapCompatibilityPosture",
	"governanceCompatibilityPosture",
	"documentationCompatibilityPosture",
	"inspectionCoveragePosture",
	"documentationPosture",
	"bootstrapPosture",
	"governancePosture",
	"noAuthorityPosture",
	"noRepairPosture",
	"noExecutionPosture",
	"noMutationPosture",
}

Types.Limits = {
	MaxInspections = 80,
	MaxObservations = 700,
	MaxFindings = 520,
	MaxAudits = 320,
	MaxValidationFailures = 260,
	MaxSnapshotHistory = 70,
	MaxPayloadDepth = 8,
	MaxPayloadNodes = 520,
	MaxStringLength = 300,
	MaxTags = 36,
	MaxEvidence = 48,
	MaxAuditFindings = 48,
	MaxInspectionChildren = 240,
}

return Types

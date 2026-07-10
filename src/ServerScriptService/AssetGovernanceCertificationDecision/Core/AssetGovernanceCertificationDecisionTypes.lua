--!strict

local Types = {}

Types.Mode = "ServerAuthoritativeAssetGovernanceCertificationDecisionMetadataRuntime"
Types.RuntimeProviderName = "assetGovernanceCertificationDecisionRuntime"
Types.SnapshotKind = "assetGovernanceCertificationDecisionRuntimeSnapshot"

Types.SchemaType = {
	GovernanceDecision = "GovernanceDecision",
	GovernanceDecisionRequirement = "GovernanceDecisionRequirement",
	GovernanceDecisionEvaluation = "GovernanceDecisionEvaluation",
	GovernanceDecisionAudit = "GovernanceDecisionAudit",
	SystemAssetGovernanceCertificationDecisionSchema = "SystemAssetGovernanceCertificationDecisionSchema",
}

Types.SchemaFields = {
	GovernanceDecision = {
		"decisionId",
		"inspectionId",
		"decisionKind",
		"decisionStatus",
		"runtimeName",
		"providerName",
		"snapshotProviderName",
		"requirementIds",
		"evaluationIds",
		"auditIds",
		"evidence",
		"tags",
		"metadata",
	},
	GovernanceDecisionRequirement = {
		"requirementId",
		"decisionId",
		"requirementKind",
		"requirementStatus",
		"runtimeName",
		"providerName",
		"snapshotProviderName",
		"evidence",
		"tags",
		"metadata",
	},
	GovernanceDecisionEvaluation = {
		"evaluationId",
		"decisionId",
		"requirementId",
		"evaluationKind",
		"evaluationStatus",
		"runtimeName",
		"providerName",
		"snapshotProviderName",
		"evidence",
		"tags",
		"metadata",
	},
	GovernanceDecisionAudit = {
		"auditId",
		"decisionId",
		"evaluationIds",
		"auditKind",
		"auditStatus",
		"reviewer",
		"evidence",
		"tags",
		"metadata",
	},
}

Types.DecisionKind = {
	CertificationDecisionEvaluation = true,
	ProviderDecisionEvaluation = true,
	RuntimeDecisionEvaluation = true,
	SnapshotDecisionEvaluation = true,
	BootstrapDecisionEvaluation = true,
	GovernanceDecisionEvaluation = true,
	DocumentationDecisionEvaluation = true,
	FutureDecisionEvaluation = true,
}

Types.DecisionStatus = {
	Evaluated = true,
	Satisfied = true,
	Unsatisfied = true,
	Warning = true,
	Deferred = true,
	Blocked = true,
}

Types.RequirementKind = {
	CopiedEvidenceRequirement = true,
	ProviderConsistencyRequirement = true,
	RuntimeConsistencyRequirement = true,
	SnapshotConsistencyRequirement = true,
	BootstrapConsistencyRequirement = true,
	GovernanceConsistencyRequirement = true,
	DocumentationConsistencyRequirement = true,
	FutureRequirement = true,
}

Types.RequirementStatus = {
	Required = true,
	Satisfied = true,
	Unsatisfied = true,
	Warning = true,
	Deferred = true,
}

Types.EvaluationKind = {
	CopiedEvidenceEvaluation = true,
	ProviderConsistencyEvaluation = true,
	RuntimeConsistencyEvaluation = true,
	SnapshotConsistencyEvaluation = true,
	BootstrapConsistencyEvaluation = true,
	GovernanceConsistencyEvaluation = true,
	DocumentationConsistencyEvaluation = true,
	FutureEvaluation = true,
}

Types.EvaluationStatus = {
	Passed = true,
	Failed = true,
	Warning = true,
	Deferred = true,
	Blocked = true,
}

Types.AuditKind = {
	DecisionAudit = true,
	RequirementAudit = true,
	EvaluationAudit = true,
	CoverageAudit = true,
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
		runtimeName = "AssetUsagePlan",
		providerName = "assetUsagePlanRuntime",
		snapshotProviderName = "assetUsagePlanRuntime",
		coordinatorName = "AssetUsagePlanCoordinator",
		documentationReference = "ASSET_USAGE_PLAN_RUNTIME.md",
	},
	{
		runtimeName = "AssetReadinessReview",
		providerName = "assetReadinessReviewRuntime",
		snapshotProviderName = "assetReadinessReviewRuntime",
		coordinatorName = "AssetReadinessReviewCoordinator",
		documentationReference = "ASSET_READINESS_REVIEW_RUNTIME.md",
	},
	{
		runtimeName = "AssetApprovalLedger",
		providerName = "assetApprovalLedgerRuntime",
		snapshotProviderName = "assetApprovalLedgerRuntime",
		coordinatorName = "AssetApprovalLedgerCoordinator",
		documentationReference = "ASSET_APPROVAL_LEDGER_RUNTIME.md",
	},
	{
		runtimeName = "AssetExecutionPermit",
		providerName = "assetExecutionPermitRuntime",
		snapshotProviderName = "assetExecutionPermitRuntime",
		coordinatorName = "AssetExecutionPermitCoordinator",
		documentationReference = "ASSET_EXECUTION_PERMIT_RUNTIME.md",
	},
	{
		runtimeName = "AssetRuntimeGate",
		providerName = "assetRuntimeGateRuntime",
		snapshotProviderName = "assetRuntimeGateRuntime",
		coordinatorName = "AssetRuntimeGateCoordinator",
		documentationReference = "ASSET_RUNTIME_GATE_RUNTIME.md",
	},
	{
		runtimeName = "AssetExecutionBoundaryReview",
		providerName = "assetExecutionBoundaryReviewRuntime",
		snapshotProviderName = "assetExecutionBoundaryReviewRuntime",
		coordinatorName = "AssetExecutionBoundaryReviewCoordinator",
		documentationReference = "ASSET_EXECUTION_BOUNDARY_REVIEW_RUNTIME.md",
	},
	{
		runtimeName = "AssetExecutionDesignContract",
		providerName = "assetExecutionDesignContractRuntime",
		snapshotProviderName = "assetExecutionDesignContractRuntime",
		coordinatorName = "AssetExecutionDesignContractCoordinator",
		documentationReference = "ASSET_EXECUTION_DESIGN_CONTRACT_RUNTIME.md",
	},
	{
		runtimeName = "AssetExecutionImplementationReadiness",
		providerName = "assetExecutionImplementationReadinessRuntime",
		snapshotProviderName = "assetExecutionImplementationReadinessRuntime",
		coordinatorName = "AssetExecutionImplementationReadinessCoordinator",
		documentationReference = "ASSET_EXECUTION_IMPLEMENTATION_READINESS_RUNTIME.md",
	},
	{
		runtimeName = "AssetExecutionImplementationContract",
		providerName = "assetExecutionImplementationContractRuntime",
		snapshotProviderName = "assetExecutionImplementationContractRuntime",
		coordinatorName = "AssetExecutionImplementationContractCoordinator",
		documentationReference = "ASSET_EXECUTION_IMPLEMENTATION_CONTRACT_RUNTIME.md",
	},
	{
		runtimeName = "AssetGovernanceIntegration",
		providerName = "assetGovernanceIntegrationRuntime",
		snapshotProviderName = "assetGovernanceIntegrationRuntime",
		coordinatorName = "AssetGovernanceIntegrationCoordinator",
		documentationReference = "ASSET_GOVERNANCE_INTEGRATION_RUNTIME.md",
	},
	{
		runtimeName = "AssetGovernanceCertification",
		providerName = "assetGovernanceCertificationRuntime",
		snapshotProviderName = "assetGovernanceCertificationRuntime",
		coordinatorName = "AssetGovernanceCertificationCoordinator",
		documentationReference = "ASSET_GOVERNANCE_CERTIFICATION_RUNTIME.md",
	},
	{
		runtimeName = "AssetGovernanceCertificationIntegration",
		providerName = "assetGovernanceCertificationIntegrationRuntime",
		snapshotProviderName = "assetGovernanceCertificationIntegrationRuntime",
		coordinatorName = "AssetGovernanceCertificationIntegrationCoordinator",
		documentationReference = "ASSET_GOVERNANCE_CERTIFICATION_INTEGRATION_RUNTIME.md",
	},
	{
		runtimeName = "AssetGovernanceCertificationInspection",
		providerName = "assetGovernanceCertificationInspectionRuntime",
		snapshotProviderName = "assetGovernanceCertificationInspectionRuntime",
		coordinatorName = "AssetGovernanceCertificationInspectionCoordinator",
		documentationReference = "ASSET_GOVERNANCE_CERTIFICATION_INSPECTION_RUNTIME.md",
	},
}

Types.RuntimeName = {}
Types.ProviderName = {}
Types.SnapshotProviderName = {}
Types.CoordinatorName = {}
Types.DocumentationReference = {}
for order, node in ipairs(Types.CertifiedRuntimeOrder) do
	Types.RuntimeName[node.runtimeName] = order
	Types.ProviderName[node.providerName] = order
	Types.SnapshotProviderName[node.snapshotProviderName] = order
	Types.CoordinatorName[node.coordinatorName] = order
	Types.DocumentationReference[node.documentationReference] = order
end

Types.PostureKeys = {
	"decisionRuntimePosture",
	"decisionEvaluationPosture",
	"decisionRequirementPosture",
	"decisionAuditPosture",
	"decisionEvidencePosture",
	"decisionIsolationPosture",
	"decisionValidationPosture",
	"decisionMetadataPosture",
	"decisionDocumentationPosture",
	"providerPosture",
	"snapshotPosture",
	"documentationPosture",
	"bootstrapPosture",
	"governancePosture",
	"noAuthorityPosture",
	"noAuthorizationPosture",
	"noApprovalPosture",
	"noRejectionPosture",
	"noExecutionPosture",
	"noRepairPosture",
	"noOrchestrationPosture",
	"noSchedulingPosture",
	"noMutationPosture",
}

Types.DocumentationFiles = {
	"ASSET_GOVERNANCE_CERTIFICATION_DECISION_RUNTIME.md",
	"GOVERNANCE_DECISION_RUNTIME.md",
	"GOVERNANCE_DECISION_REQUIREMENT_RUNTIME.md",
	"GOVERNANCE_DECISION_EVALUATION_RUNTIME.md",
	"GOVERNANCE_DECISION_AUDIT_RUNTIME.md",
	"ASSET_GOVERNANCE_CERTIFICATION_DECISION_VALIDATION.md",
	"ASSET_GOVERNANCE_CERTIFICATION_DECISION_SERIALIZATION.md",
	"ASSET_GOVERNANCE_CERTIFICATION_DECISION_DIAGNOSTICS.md",
	"ASSET_GOVERNANCE_CERTIFICATION_DECISION_SELF_CHECKS.md",
	"ASSET_GOVERNANCE_CERTIFICATION_DECISION_RUNTIME_LIMITS.md",
	"ASSET_GOVERNANCE_CERTIFICATION_DECISION_PRODUCTION_REVIEW.md",
}

Types.BootstrapDependencyOrder = {
	"AssetGovernanceCertificationInspectionCoordinator",
}

Types.Limits = {
	MaxDecisions = 120,
	MaxRequirements = 520,
	MaxEvaluations = 720,
	MaxAudits = 320,
	MaxValidationFailures = 260,
	MaxSnapshotHistory = 70,
	MaxPayloadDepth = 8,
	MaxPayloadNodes = 540,
	MaxStringLength = 300,
	MaxTags = 36,
	MaxEvidence = 64,
	MaxDecisionChildren = 240,
}

return Types

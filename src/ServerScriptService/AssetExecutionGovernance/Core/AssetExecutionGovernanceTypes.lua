--!strict

local Types = {}

Types.Mode = "ServerAuthoritativeAssetExecutionGovernanceMetadataRuntime"
Types.RuntimeProviderName = "assetExecutionGovernanceRuntime"
Types.SnapshotKind = "assetExecutionGovernanceRuntimeSnapshot"

Types.SchemaType = {
	ExecutionGovernance = "ExecutionGovernance",
	ExecutionGovernanceRequirement = "ExecutionGovernanceRequirement",
	ExecutionGovernanceAssessment = "ExecutionGovernanceAssessment",
	ExecutionGovernanceFinding = "ExecutionGovernanceFinding",
	ExecutionGovernanceAudit = "ExecutionGovernanceAudit",
}

Types.SchemaFields = {
	ExecutionGovernance = {
		"governanceId",
		"decisionId",
		"executionReadinessId",
		"governanceKind",
		"governanceStatus",
		"runtimeName",
		"providerName",
		"snapshotProviderName",
		"requirementIds",
		"assessmentIds",
		"findingIds",
		"auditIds",
		"evidence",
		"tags",
		"metadata",
	},
	ExecutionGovernanceRequirement = {
		"requirementId",
		"governanceId",
		"requirementKind",
		"requirementStatus",
		"runtimeName",
		"providerName",
		"snapshotProviderName",
		"required",
		"evidence",
		"tags",
		"metadata",
	},
	ExecutionGovernanceAssessment = {
		"assessmentId",
		"governanceId",
		"requirementId",
		"assessmentKind",
		"assessmentStatus",
		"runtimeName",
		"providerName",
		"snapshotProviderName",
		"evidence",
		"tags",
		"metadata",
	},
	ExecutionGovernanceFinding = {
		"findingId",
		"governanceId",
		"assessmentId",
		"findingKind",
		"findingSeverity",
		"findingStatus",
		"summary",
		"evidence",
		"tags",
		"metadata",
	},
	ExecutionGovernanceAudit = {
		"auditId",
		"governanceId",
		"assessmentIds",
		"findingIds",
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

Types.GovernanceKind = {
	DecisionEvidenceGovernance = true,
	ExecutionReadinessGovernance = true,
	ProviderGovernance = true,
	RuntimeGovernance = true,
	SnapshotGovernance = true,
	BootstrapGovernance = true,
	DocumentationGovernance = true,
	BoundaryGovernance = true,
	IsolationGovernance = true,
	FutureGovernance = true,
}

Types.GovernanceStatus = {
	Declared = true,
	UnderReview = true,
	Satisfied = true,
	Unsatisfied = true,
	Blocked = true,
	Deferred = true,
	Warning = true,
}

Types.RequirementKind = {
	DecisionEvidenceRequirement = true,
	ExecutionReadinessRequirement = true,
	ProviderConsistencyRequirement = true,
	RuntimeConsistencyRequirement = true,
	SnapshotConsistencyRequirement = true,
	BootstrapConsistencyRequirement = true,
	DocumentationConsistencyRequirement = true,
	BoundaryRequirement = true,
	IsolationRequirement = true,
	FutureRequirement = true,
}

Types.RequirementStatus = {
	Required = true,
	Satisfied = true,
	Unsatisfied = true,
	Deferred = true,
	Warning = true,
}

Types.AssessmentKind = {
	DecisionEvidenceAssessment = true,
	ExecutionReadinessAssessment = true,
	ProviderConsistencyAssessment = true,
	RuntimeConsistencyAssessment = true,
	SnapshotConsistencyAssessment = true,
	BootstrapConsistencyAssessment = true,
	DocumentationConsistencyAssessment = true,
	BoundaryAssessment = true,
	IsolationAssessment = true,
	FutureAssessment = true,
}

Types.AssessmentStatus = {
	Passed = true,
	Failed = true,
	Blocked = true,
	Deferred = true,
	Warning = true,
}

Types.FindingKind = {
	MissingEvidence = true,
	CompatibilityDrift = true,
	ProviderDrift = true,
	RuntimeDrift = true,
	SnapshotDrift = true,
	BootstrapDrift = true,
	DocumentationDrift = true,
	BoundaryViolation = true,
	IsolationViolation = true,
	UnsafeMetadata = true,
	FutureFinding = true,
}

Types.FindingSeverity = {
	Informational = true,
	Low = true,
	Medium = true,
	High = true,
	Critical = true,
}

Types.FindingStatus = {
	Open = true,
	Reviewed = true,
	Acknowledged = true,
	Deferred = true,
	ResolvedMetadataOnly = true,
}

Types.AuditKind = {
	GovernanceAudit = true,
	RequirementAudit = true,
	AssessmentAudit = true,
	FindingAudit = true,
	CoverageAudit = true,
	BoundaryAudit = true,
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

Types.PostureKeys = {
	"assetExecutionGovernancePosture",
	"governanceMetadataPosture",
	"governanceRequirementPosture",
	"governanceAssessmentPosture",
	"governanceFindingPosture",
	"governanceAuditPosture",
	"governanceBoundaryPosture",
	"governanceIsolationPosture",
	"governanceValidationPosture",
	"providerPosture",
	"snapshotPosture",
	"bootstrapPosture",
	"documentationPosture",
	"noAuthorizationPosture",
	"noOperationalRejectionPosture",
	"noPermissionPosture",
	"noRoutingPosture",
	"noDispatchPosture",
	"noQueuePosture",
	"noSchedulingPosture",
	"noOrchestrationPosture",
	"noExecutionPosture",
	"noMutationPosture",
	"noAuthorityPosture",
}

Types.DocumentationFiles = {
	"ASSET_EXECUTION_GOVERNANCE_RUNTIME.md",
	"ASSET_EXECUTION_GOVERNANCE_VALIDATION.md",
	"ASSET_EXECUTION_GOVERNANCE_SERIALIZATION.md",
	"ASSET_EXECUTION_GOVERNANCE_DIAGNOSTICS.md",
	"ASSET_EXECUTION_GOVERNANCE_SELF_CHECKS.md",
	"ASSET_EXECUTION_GOVERNANCE_RUNTIME_LIMITS.md",
	"ASSET_EXECUTION_GOVERNANCE_AUDIT.md",
	"ASSET_EXECUTION_GOVERNANCE_PRODUCTION_REVIEW.md",
	"EXECUTION_GOVERNANCE_RUNTIME.md",
	"EXECUTION_GOVERNANCE_REQUIREMENT_RUNTIME.md",
	"EXECUTION_GOVERNANCE_ASSESSMENT_RUNTIME.md",
	"EXECUTION_GOVERNANCE_FINDING_RUNTIME.md",
	"EXECUTION_GOVERNANCE_AUDIT_RUNTIME.md",
}

Types.BootstrapDependencyOrder = {
	"AssetGovernanceCertificationDecisionCoordinator",
}

Types.Limits = {
	MaxGovernance = 140,
	MaxRequirements = 540,
	MaxAssessments = 720,
	MaxFindings = 420,
	MaxAudits = 320,
	MaxValidationFailures = 260,
	MaxSnapshotHistory = 70,
	MaxPayloadDepth = 8,
	MaxPayloadNodes = 560,
	MaxStringLength = 300,
	MaxTags = 36,
	MaxEvidence = 64,
	MaxChildReferences = 260,
	MaxSummaryLength = 180,
}

return Types

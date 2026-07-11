--!strict

local Types = {}

Types.Mode = "ServerAuthoritativeAssetExecutionAuthorizationMetadataRuntime"
Types.RuntimeProviderName = "assetExecutionAuthorizationRuntime"
Types.SnapshotKind = "assetExecutionAuthorizationRuntimeSnapshot"
Types.RuntimeName = "AssetExecutionAuthorization"
Types.CoordinatorName = "AssetExecutionAuthorizationCoordinator"

Types.SchemaType = {
	ExecutionAuthorization = "ExecutionAuthorization",
	ExecutionAuthorizationRequirement = "ExecutionAuthorizationRequirement",
	ExecutionAuthorizationEvaluation = "ExecutionAuthorizationEvaluation",
	ExecutionAuthorizationBoundary = "ExecutionAuthorizationBoundary",
	ExecutionAuthorizationAudit = "ExecutionAuthorizationAudit",
}

Types.SchemaFields = {
	ExecutionAuthorization = {
		"authorizationId",
		"governanceId",
		"readinessId",
		"authorizationKind",
		"authorizationStatus",
		"runtimeName",
		"providerName",
		"snapshotProviderName",
		"requirementIds",
		"evaluationIds",
		"boundaryIds",
		"auditIds",
		"evidence",
		"tags",
		"metadata",
	},
	ExecutionAuthorizationRequirement = {
		"requirementId",
		"authorizationId",
		"requirementKind",
		"requirementStatus",
		"required",
		"evidence",
		"tags",
		"metadata",
	},
	ExecutionAuthorizationEvaluation = {
		"evaluationId",
		"authorizationId",
		"requirementId",
		"evaluationKind",
		"evaluationStatus",
		"evaluator",
		"evidence",
		"tags",
		"metadata",
	},
	ExecutionAuthorizationBoundary = {
		"boundaryId",
		"authorizationId",
		"boundaryKind",
		"boundaryStatus",
		"summary",
		"evidence",
		"tags",
		"metadata",
	},
	ExecutionAuthorizationAudit = {
		"auditId",
		"authorizationId",
		"evaluationIds",
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

Types.AuthorizationKind = {
	GovernanceAuthorization = true,
	ReadinessAuthorization = true,
	BoundaryAuthorization = true,
	RuntimeAuthorization = true,
	ProviderAuthorization = true,
	SnapshotAuthorization = true,
	DocumentationAuthorization = true,
	FutureAuthorization = true,
}

Types.AuthorizationStatus = {
	Declared = true,
	UnderReview = true,
	Satisfied = true,
	Unsatisfied = true,
	Deferred = true,
	Warning = true,
	Blocked = true,
}

Types.RequirementKind = {
	GovernanceRequirement = true,
	ReadinessRequirement = true,
	BoundaryRequirement = true,
	RuntimeRequirement = true,
	ProviderRequirement = true,
	SnapshotRequirement = true,
	DocumentationRequirement = true,
	FutureRequirement = true,
}

Types.RequirementStatus = {
	Required = true,
	Satisfied = true,
	Unsatisfied = true,
	Deferred = true,
	Warning = true,
	Blocked = true,
}

Types.EvaluationKind = {
	GovernanceEvaluation = true,
	ReadinessEvaluation = true,
	BoundaryEvaluation = true,
	RuntimeEvaluation = true,
	ProviderEvaluation = true,
	SnapshotEvaluation = true,
	DocumentationEvaluation = true,
	FutureEvaluation = true,
}

Types.EvaluationStatus = {
	Passed = true,
	Failed = true,
	Deferred = true,
	Warning = true,
	Blocked = true,
}

Types.BoundaryKind = {
	NoAssetOperation = true,
	NoRuntimeBridge = true,
	NoWorkRouting = true,
	NoWorkDispatch = true,
	NoWorkScheduling = true,
	NoSystemOrchestration = true,
	NoGameplayMutation = true,
	NoPresentationMutation = true,
	NoSaveMutation = true,
	FutureExecutionSeparate = true,
}

Types.BoundaryStatus = {
	Declared = true,
	Satisfied = true,
	Unsatisfied = true,
	Deferred = true,
	Warning = true,
	Blocked = true,
}

Types.AuditKind = {
	AuthorizationAudit = true,
	RequirementAudit = true,
	EvaluationAudit = true,
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
	"authorizationRuntimePosture",
	"authorizationIsolationPosture",
	"authorizationBoundaryPosture",
	"authorizationEvaluationPosture",
	"authorizationAuditPosture",
	"authorizationRequirementPosture",
	"noExecution",
	"noRouting",
	"noDispatch",
	"noScheduler",
	"noOrchestration",
	"noGameplay",
	"noPresentation",
	"noSave",
	"noAuthorityEscalation",
}

Types.DocumentationFiles = {
	"ASSET_EXECUTION_AUTHORIZATION_RUNTIME.md",
	"ASSET_EXECUTION_AUTHORIZATION_VALIDATION.md",
	"ASSET_EXECUTION_AUTHORIZATION_SERIALIZATION.md",
	"ASSET_EXECUTION_AUTHORIZATION_DIAGNOSTICS.md",
	"ASSET_EXECUTION_AUTHORIZATION_SELF_CHECKS.md",
	"ASSET_EXECUTION_AUTHORIZATION_RUNTIME_LIMITS.md",
	"ASSET_EXECUTION_AUTHORIZATION_PRODUCTION_REVIEW.md",
	"ASSET_EXECUTION_AUTHORIZATION_AUDIT.md",
	"AUTHORIZATION_RUNTIME.md",
	"AUTHORIZATION_REQUIREMENT_RUNTIME.md",
	"AUTHORIZATION_EVALUATION_RUNTIME.md",
	"AUTHORIZATION_BOUNDARY_RUNTIME.md",
	"AUTHORIZATION_AUDIT_RUNTIME.md",
}

Types.BootstrapDependencyOrder = {
	"AssetExecutionGovernanceCoordinator",
}

Types.GovernanceSnapshotProviders = {
	"assetExecutionAuthorizationRuntime",
}

Types.IdentityOrder = {
	"AssetExecutionGovernanceCoordinator",
	"AssetExecutionAuthorizationCoordinator",
	"assetExecutionAuthorizationRuntime",
	"assetExecutionAuthorizationRuntimeSnapshot",
}

Types.Limits = {
	MaxAuthorizations = 180,
	MaxRequirements = 540,
	MaxEvaluations = 540,
	MaxBoundaries = 360,
	MaxAudits = 260,
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

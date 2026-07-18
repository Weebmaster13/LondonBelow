--!strict

local Types = {}

Types.RuntimeName = "ExecutionAuthorizationRuntime"
Types.CoordinatorName = "ExecutionAuthorizationCoordinator"
Types.RuntimeProviderName = "executionAuthorizationRuntime"
Types.SnapshotKind = "executionAuthorizationRuntimeSnapshot"
Types.SchemaVersion = 1
Types.PolicyVersion = "1.0.0"
Types.RuleSetVersion = "1.0.0"
Types.DecisionVersion = "1.0.0"
Types.StableTimestamp = "2026-07-18T03:30:00.000Z"
Types.RequiredPlanningVersion = "1.0.0"

Types.LifecycleState = {
	Uninitialized = "UNINITIALIZED",
	Bootstrapping = "BOOTSTRAPPING",
	PolicyLoading = "POLICY_LOADING",
	RuleValidation = "RULE_VALIDATION",
	AuthorizationEvaluation = "AUTHORIZATION_EVALUATION",
	DecisionBuilding = "DECISION_BUILDING",
	DecisionPublication = "DECISION_PUBLICATION",
	Complete = "COMPLETE",
	Failed = "FAILED",
}

Types.Decision = {
	Authorized = "AUTHORIZED",
	Denied = "DENIED",
	Blocked = "BLOCKED",
	Invalid = "INVALID",
	Unknown = "UNKNOWN",
}

Types.AuthorizationClassification = {
	MetadataOnly = "METADATA_ONLY",
	PlanningAuthorizedButExecutionBlocked = "PLANNING_AUTHORIZED_BUT_EXECUTION_BLOCKED",
	PlanningDenied = "PLANNING_DENIED",
	Invalid = "INVALID",
}

Types.PolicyKind = {
	PlanningIntegrity = "PLANNING_INTEGRITY",
	RuntimeTruth = "RUNTIME_TRUTH",
	AuthorityIdentity = "AUTHORITY_IDENTITY",
	VersionCompatibility = "VERSION_COMPATIBILITY",
}

Types.RuleKind = {
	RuntimeBlocked = "RUNTIME_BLOCKED",
	PlanningComplete = "PLANNING_COMPLETE",
	DependenciesValid = "DEPENDENCIES_VALID",
	ConstraintsValid = "CONSTRAINTS_VALID",
	EligibilityNotInvalid = "ELIGIBILITY_NOT_INVALID",
	RuntimeTruthPreserved = "RUNTIME_TRUTH_PRESERVED",
	AuthorityIdentitySupported = "AUTHORITY_IDENTITY_SUPPORTED",
	PlanningVersionSupported = "PLANNING_VERSION_SUPPORTED",
}

Types.RuleOutcome = {
	Pass = "PASS",
	Fail = "FAIL",
	Blocked = "BLOCKED",
	Invalid = "INVALID",
}

Types.PublicationState = {
	Draft = "DRAFT",
	Published = "PUBLISHED",
	Rejected = "REJECTED",
}

Types.ResultCode = {
	Ok = "OK",
	InvalidSchema = "INVALID_SCHEMA",
	DuplicatePolicy = "DUPLICATE_POLICY",
	DuplicateRule = "DUPLICATE_RULE",
	MissingPlanningPublication = "MISSING_PLANNING_PUBLICATION",
	VersionMismatch = "VERSION_MISMATCH",
	UnsupportedAuthority = "UNSUPPORTED_AUTHORITY",
	InvalidDecision = "INVALID_DECISION",
	InvalidClassification = "INVALID_CLASSIFICATION",
	PublicationRejected = "PUBLICATION_REJECTED",
	UnsafePayload = "UNSAFE_PAYLOAD",
}

Types.RuntimeTruth = {
	sessionFailureReason = "SESSION_NOT_VISIBLE",
	executionBlocked = true,
	runnerInvoked = false,
	structuredResultCaptured = false,
	transportCreated = false,
	envelopeTransmitted = false,
	acknowledgementReceived = false,
	runtimeEvidenceGenerated = false,
}

Types.Limits = {
	MaxPolicies = 32,
	MaxRules = 64,
	MaxEvaluatedRules = 64,
	MaxAuditRecords = 256,
	MaxValidationFailures = 64,
	MaxSnapshots = 32,
	MaxStringLength = 160,
	MaxMetadataKeys = 32,
	MaxDepth = 8,
}

Types.PolicyFields = {
	"policyId",
	"policyKind",
	"policyVersion",
	"required",
	"ruleIds",
	"metadata",
}

Types.RuleFields = {
	"ruleId",
	"policyId",
	"ruleKind",
	"expected",
	"metadata",
}

Types.DecisionFields = {
	"authorizationId",
	"planningId",
	"planningVersion",
	"ruleSetVersion",
	"policyVersion",
	"decision",
	"evaluatedRules",
	"blockedRuntimeTruth",
	"authorizationClassification",
	"metadata",
	"orderingKey",
	"publicationState",
}

return Types

--!strict

local Types = {}

Types.RuntimeName = "ExecutionPlanningRuntime"
Types.CoordinatorName = "ExecutionPlanningCoordinator"
Types.RuntimeProviderName = "executionPlanningRuntime"
Types.SnapshotKind = "executionPlanningRuntimeSnapshot"
Types.SchemaVersion = 1
Types.PlanVersion = "1.0.0"
Types.StableTimestamp = "2026-07-18T03:00:00.000Z"

Types.LifecycleState = {
	Uninitialized = "UNINITIALIZED",
	Bootstrapping = "BOOTSTRAPPING",
	GraphBuilding = "GRAPH_BUILDING",
	DependencyValidation = "DEPENDENCY_VALIDATION",
	ConstraintValidation = "CONSTRAINT_VALIDATION",
	EligibilityAnalysis = "ELIGIBILITY_ANALYSIS",
	PlanFinalization = "PLAN_FINALIZATION",
	PlanPublication = "PLAN_PUBLICATION",
	Complete = "COMPLETE",
	Failed = "FAILED",
}

Types.EligibilityState = {
	Eligible = "ELIGIBLE",
	NotEligible = "NOT_ELIGIBLE",
	Blocked = "BLOCKED",
	Waiting = "WAITING",
	Invalid = "INVALID",
	Unknown = "UNKNOWN",
}

Types.PublicationState = {
	Draft = "DRAFT",
	Published = "PUBLISHED",
	Rejected = "REJECTED",
}

Types.PlanningClassification = {
	DefinitionOnly = "DEFINITION_ONLY",
	BlockedRuntimeTruthPreserved = "BLOCKED_RUNTIME_TRUTH_PRESERVED",
	FutureExecutionPlanning = "FUTURE_EXECUTION_PLANNING",
	Invalid = "INVALID",
}

Types.ConstraintKind = {
	RuntimeBlocked = "RUNTIME_BLOCKED",
	AuthorityUnavailable = "AUTHORITY_UNAVAILABLE",
	RuntimeTruthPreserved = "RUNTIME_TRUTH_PRESERVED",
	VerificationIncomplete = "VERIFICATION_INCOMPLETE",
	PlanningFrozen = "PLANNING_FROZEN",
	PublicationLocked = "PUBLICATION_LOCKED",
}

Types.DependencyKind = {
	Requires = "REQUIRES",
	BlocksUntil = "BLOCKS_UNTIL",
	Documents = "DOCUMENTS",
}

Types.NodeKind = {
	Authority = "AUTHORITY",
	Runtime = "RUNTIME",
	PlanningBoundary = "PLANNING_BOUNDARY",
	VerificationInput = "VERIFICATION_INPUT",
}

Types.ResultCode = {
	Ok = "OK",
	InvalidSchema = "INVALID_SCHEMA",
	DuplicateNode = "DUPLICATE_NODE",
	DuplicateDependency = "DUPLICATE_DEPENDENCY",
	MissingDependency = "MISSING_DEPENDENCY",
	CyclicDependency = "CYCLIC_DEPENDENCY",
	OrphanNode = "ORPHAN_NODE",
	IllegalOwnership = "ILLEGAL_OWNERSHIP",
	VersionMismatch = "VERSION_MISMATCH",
	UnknownAuthority = "UNKNOWN_AUTHORITY",
	ConstraintRejected = "CONSTRAINT_REJECTED",
	PublicationLocked = "PUBLICATION_LOCKED",
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
	MaxNodes = 64,
	MaxDependencies = 128,
	MaxConstraints = 128,
	MaxAuditRecords = 256,
	MaxValidationFailures = 64,
	MaxSnapshots = 32,
	MaxStringLength = 160,
	MaxMetadataKeys = 32,
	MaxDepth = 8,
}

Types.NodeFields = {
	"nodeId",
	"nodeKind",
	"authorityOwner",
	"version",
	"orderingKey",
	"planningClassification",
	"metadata",
}

Types.DependencyFields = {
	"dependencyId",
	"fromNodeId",
	"toNodeId",
	"dependencyKind",
	"requiredVersion",
	"metadata",
}

Types.ConstraintFields = {
	"constraintId",
	"nodeId",
	"constraintKind",
	"required",
	"metadata",
}

Types.PublicationFields = {
	"planId",
	"planVersion",
	"graphId",
	"generationId",
	"createdAt",
	"planningClassification",
	"planningHash",
	"dependencySummary",
	"constraintSummary",
	"eligibilitySummary",
	"runtimeTruth",
	"publicationState",
}

Types.CoordinatorApiOrder = {
	"initialize",
	"start",
	"shutdown",
	"plan",
	"inspect",
	"getSnapshot",
	"validate",
	"runSelfChecks",
}

return Types

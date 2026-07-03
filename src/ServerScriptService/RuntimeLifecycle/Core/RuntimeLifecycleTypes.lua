--!strict
-- Shared constants for Phase 38 Runtime Lifecycle Foundation.

local Types = {}

Types.Mode = "ServerAuthoritativeRuntimeLifecycleSchemaRuntime"

Types.SchemaType = {
	LifecycleStateSchema = "LifecycleStateSchema",
	LifecycleTransitionSchema = "LifecycleTransitionSchema",
	LifecyclePolicySchema = "LifecyclePolicySchema",
	LifecycleGuardSchema = "LifecycleGuardSchema",
	LifecycleEventSchema = "LifecycleEventSchema",
	LifecycleFailureSchema = "LifecycleFailureSchema",
	LifecycleRecoverySchema = "LifecycleRecoverySchema",
	LifecycleCheckpointSchema = "LifecycleCheckpointSchema",
	LifecycleAuditSchema = "LifecycleAuditSchema",
	LifecycleCompatibilitySchema = "LifecycleCompatibilitySchema",
	SystemRuntimeLifecycleSchema = "SystemRuntimeLifecycleSchema",
}

Types.LifecycleState = {
	Unknown = true,
	Declared = true,
	Registered = true,
	Validated = true,
	Configured = true,
	Ready = true,
	Starting = true,
	Started = true,
	Paused = true,
	Suspended = true,
	Degraded = true,
	Recovering = true,
	Stopping = true,
	Stopped = true,
	Failed = true,
	Disabled = true,
	Deprecated = true,
	Archived = true,
	FutureOnly = true,
}

Types.TransitionKind = {
	Declare = true,
	Register = true,
	Validate = true,
	Configure = true,
	Prepare = true,
	Start = true,
	Pause = true,
	Suspend = true,
	Resume = true,
	Degrade = true,
	Recover = true,
	Stop = true,
	Fail = true,
	Disable = true,
	Deprecate = true,
	Archive = true,
	FutureOnly = true,
}

Types.PolicyKind = {
	RequiredState = true,
	ForbiddenState = true,
	AllowedTransition = true,
	ForbiddenTransition = true,
	Precondition = true,
	Postcondition = true,
	RecoveryPolicy = true,
	FailurePolicy = true,
	CompatibilityPolicy = true,
	FuturePolicy = true,
}

Types.GuardKind = {
	DependencyGuard = true,
	ConfigurationGuard = true,
	GovernanceGuard = true,
	SafetyGuard = true,
	CompatibilityGuard = true,
	RuntimeGraphGuard = true,
	SecurityGuard = true,
	SaveGuard = true,
	PresentationGuard = true,
	FutureGuard = true,
}

Types.EventKind = {
	StateDeclared = true,
	TransitionDeclared = true,
	PolicyDeclared = true,
	GuardDeclared = true,
	FailureRecorded = true,
	RecoveryDeclared = true,
	CheckpointDeclared = true,
	AuditRecorded = true,
	CompatibilityDeclared = true,
	FutureEvent = true,
}

Types.FailureKind = {
	ValidationFailure = true,
	DependencyFailure = true,
	ConfigurationFailure = true,
	GovernanceFailure = true,
	SafetyFailure = true,
	CompatibilityFailure = true,
	RuntimeGraphFailure = true,
	UnknownFailure = true,
	FutureFailure = true,
}

Types.RecoveryKind = {
	NoRecovery = true,
	ManualReview = true,
	RetryLater = true,
	RestorePreviousSchema = true,
	RevalidateSchema = true,
	DisableSchema = true,
	FutureRecovery = true,
}

Types.CompatibilityKind = {
	Compatible = true,
	RequiresPolicy = true,
	DeprecatedState = true,
	ForbiddenTransition = true,
	FutureCompatible = true,
	Incompatible = true,
	Unknown = true,
}

Types.ResultCode = {
	Ok = "Ok",
	InvalidRequest = "InvalidRequest",
	DuplicateState = "DuplicateState",
	DuplicateTransition = "DuplicateTransition",
	DuplicatePolicy = "DuplicatePolicy",
	DuplicateGuard = "DuplicateGuard",
	DuplicateEvent = "DuplicateEvent",
	DuplicateFailure = "DuplicateFailure",
	DuplicateRecovery = "DuplicateRecovery",
	DuplicateCheckpoint = "DuplicateCheckpoint",
	DuplicateAudit = "DuplicateAudit",
	DuplicateCompatibility = "DuplicateCompatibility",
	UnsafePayload = "UnsafePayload",
}

Types.Limits = {
	MaxLifecycleStates = 600,
	MaxTransitions = 1200,
	MaxPolicies = 900,
	MaxGuards = 900,
	MaxEvents = 900,
	MaxFailures = 700,
	MaxRecoveries = 700,
	MaxCheckpoints = 700,
	MaxAudits = 500,
	MaxCompatibilityRecords = 700,
	MaxValidationFailures = 220,
	MaxSnapshotHistory = 80,
	MaxPayloadDepth = 9,
	MaxPayloadNodes = 420,
	MaxPayloadStringLength = 640,
	MaxTagsPerSchema = 32,
	MaxPolicyRefs = 96,
	MaxGuardRefs = 96,
	MaxAuditFindings = 96,
}

return Types

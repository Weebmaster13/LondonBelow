--!strict

local Types = {}

Types.RuntimeName = "EnvironmentalInteractionRuntime"
Types.CoordinatorName = "EnvironmentalInteractionCoordinator"
Types.SchemaVersion = 1

Types.Family = {
	BinaryMechanism = "BinaryMechanism",
	InspectableObject = "InspectableObject",
	MomentaryActuator = "MomentaryActuator",
}

Types.Action = {
	Open = "OPEN",
	Close = "CLOSE",
	Toggle = "TOGGLE",
	Inspect = "INSPECT",
	Activate = "ACTIVATE",
	Reset = "RESET",
}

Types.State = {
	Open = "OPEN",
	Closed = "CLOSED",
	On = "ON",
	Off = "OFF",
	Available = "AVAILABLE",
	Inspected = "INSPECTED",
	Ready = "READY",
	Active = "ACTIVE",
	Cooldown = "COOLDOWN",
	Disabled = "DISABLED",
}

Types.ResultCode = {
	Ok = "OK",
	EnvironmentObjectNotFound = "ENVIRONMENT_OBJECT_NOT_FOUND",
	EnvironmentObjectDisabled = "ENVIRONMENT_OBJECT_DISABLED",
	EnvironmentFamilyNotFound = "ENVIRONMENT_FAMILY_NOT_FOUND",
	EnvironmentActionUnsupported = "ENVIRONMENT_ACTION_UNSUPPORTED",
	EnvironmentTransitionInvalid = "ENVIRONMENT_TRANSITION_INVALID",
	EnvironmentStateInvalid = "ENVIRONMENT_STATE_INVALID",
	EnvironmentDependencyMissing = "ENVIRONMENT_DEPENDENCY_MISSING",
	EnvironmentAlreadyInspected = "ENVIRONMENT_ALREADY_INSPECTED",
	EnvironmentResetRequired = "ENVIRONMENT_RESET_REQUIRED",
	EnvironmentConfigurationInvalid = "ENVIRONMENT_CONFIGURATION_INVALID",
	EnvironmentHandlerFailed = "ENVIRONMENT_HANDLER_FAILED",
	InteractionRuntimeRejected = "INTERACTION_RUNTIME_REJECTED",
	StateRevisionMismatch = "STATE_REVISION_MISMATCH",
	TransitionSuperseded = "TRANSITION_SUPERSEDED",
	BatchRegistrationFailed = "BATCH_REGISTRATION_FAILED",
	ReconciliationFailed = "RECONCILIATION_FAILED",
	FixtureBindingInvalid = "FIXTURE_BINDING_INVALID",
	DuplicateObjectId = "DUPLICATE_ENVIRONMENT_OBJECT_ID",
	DuplicateBinding = "DUPLICATE_ENVIRONMENT_BINDING",
	DuplicateCompletion = "DUPLICATE_ENVIRONMENT_COMPLETION",
	RuntimeUnavailable = "RUNTIME_UNAVAILABLE",
}

Types.Limits = {
	MaxObjects = 260,
	MaxBindings = 260,
	MaxActions = 12,
	MaxTransitions = 48,
	MaxMetadataDepth = 6,
	MaxMetadataNodes = 180,
	MaxStringLength = 512,
	MaxEvidence = 260,
	MaxFailures = 180,
	MaxSnapshots = 80,
	MaxDependenciesPerObject = 12,
	MaxDependencyDepth = 8,
}

return Types

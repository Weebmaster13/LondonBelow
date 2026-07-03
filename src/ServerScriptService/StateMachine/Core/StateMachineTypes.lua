--!strict
-- Shared constants and runtime limits for Phase 44 State Machine Runtime Foundation.

local Types = {}

Types.Mode = "ServerAuthoritativeStateMachineSchemaRuntime"

Types.SchemaType = {
	StateMachineDefinitionSchema = "StateMachineDefinitionSchema",
	StateMachineStateSchema = "StateMachineStateSchema",
	StateMachineTransitionSchema = "StateMachineTransitionSchema",
	StateMachineGuardSchema = "StateMachineGuardSchema",
	StateMachineInputSchema = "StateMachineInputSchema",
	StateMachineOutputSchema = "StateMachineOutputSchema",
	StateMachineGroupSchema = "StateMachineGroupSchema",
	StateMachineDependencySchema = "StateMachineDependencySchema",
	StateMachineOutcomeSchema = "StateMachineOutcomeSchema",
	StateMachineAuditSchema = "StateMachineAuditSchema",
	SystemStateMachineSchema = "SystemStateMachineSchema",
}

Types.Domain = {
	Core = true,
	Gameplay = true,
	Observation = true,
	Director = true,
	Horror = true,
	Monster = true,
	MonsterAI = true,
	Narrative = true,
	Presentation = true,
	Puzzle = true,
	Interaction = true,
	Inventory = true,
	Objective = true,
	World = true,
	Session = true,
	Persistence = true,
	Condition = true,
	Trigger = true,
	RuleEngine = true,
	Scheduler = true,
	Lifecycle = true,
	EventGraph = true,
	RuntimeGraph = true,
	Accessibility = true,
	Security = true,
	Localization = true,
	Performance = true,
	ContentRegistry = true,
	System = true,
	Future = true,
}

Types.StateKind = {
	Idle = true,
	Active = true,
	Inactive = true,
	Entered = true,
	Exited = true,
	Pending = true,
	Satisfied = true,
	Failed = true,
	Blocked = true,
	Suspended = true,
	Disabled = true,
	Archived = true,
	FutureState = true,
}

Types.TransitionKind = {
	Manual = true,
	Automatic = true,
	Conditional = true,
	Triggered = true,
	Timed = true,
	Deferred = true,
	Recovery = true,
	Failure = true,
	FutureTransition = true,
}

Types.GuardKind = {
	NoGuard = true,
	ConditionGuard = true,
	RuleGuard = true,
	TriggerGuard = true,
	PermissionGuard = true,
	LifecycleGuard = true,
	RuntimeGuard = true,
	FutureGuard = true,
}

Types.InputKind = {
	NoInput = true,
	SignalInput = true,
	TriggerInput = true,
	EventInput = true,
	ConditionInput = true,
	RuleInput = true,
	RuntimeInput = true,
	FutureInput = true,
}

Types.OutputKind = {
	NoOutput = true,
	SignalOutput = true,
	TriggerOutput = true,
	EventOutput = true,
	ConditionOutput = true,
	RuleOutput = true,
	RuntimeOutput = true,
	FutureOutput = true,
}

Types.GroupKind = {
	Sequential = true,
	Parallel = true,
	Exclusive = true,
	Priority = true,
	Nested = true,
	FutureGroup = true,
}

Types.OutcomeKind = {
	Entered = true,
	Exited = true,
	Transitioned = true,
	Blocked = true,
	Deferred = true,
	Failed = true,
	Unknown = true,
	FutureOutcome = true,
}

Types.DependencyKind = {
	Requires = true,
	Blocks = true,
	ConflictsWith = true,
	SoftOrder = true,
	FutureDependency = true,
}

Types.Limits = {
	MaxStateMachines = 700,
	MaxStates = 900,
	MaxTransitions = 1100,
	MaxGuards = 900,
	MaxInputs = 900,
	MaxOutputs = 900,
	MaxGroups = 700,
	MaxDependencies = 900,
	MaxOutcomes = 700,
	MaxAudits = 500,
	MaxValidationFailures = 240,
	MaxSnapshotHistory = 80,
	MaxPayloadDepth = 9,
	MaxPayloadNodes = 460,
	MaxPayloadStringLength = 700,
	MaxTagsPerSchema = 32,
	MaxMachineStates = 160,
	MaxMachineTransitions = 180,
	MaxMachineGuards = 140,
	MaxMachineInputs = 140,
	MaxMachineOutputs = 140,
	MaxGroupMembers = 160,
	MaxAuditFindings = 96,
}

return Types

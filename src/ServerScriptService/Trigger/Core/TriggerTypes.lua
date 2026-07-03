--!strict
-- Shared constants and runtime limits for Phase 43 Trigger Runtime Foundation.

local Types = {}

Types.Mode = "ServerAuthoritativeTriggerSchemaRuntime"

Types.SchemaType = {
	TriggerDefinitionSchema = "TriggerDefinitionSchema",
	TriggerCategorySchema = "TriggerCategorySchema",
	TriggerSourceSchema = "TriggerSourceSchema",
	TriggerTargetSchema = "TriggerTargetSchema",
	TriggerEventSchema = "TriggerEventSchema",
	TriggerFilterSchema = "TriggerFilterSchema",
	TriggerConditionSchema = "TriggerConditionSchema",
	TriggerDependencySchema = "TriggerDependencySchema",
	TriggerGroupSchema = "TriggerGroupSchema",
	TriggerOutcomeSchema = "TriggerOutcomeSchema",
	TriggerAuditSchema = "TriggerAuditSchema",
	SystemTriggerSchema = "SystemTriggerSchema",
}

Types.Domain = {
	Core = true,
	Gameplay = true,
	Observation = true,
	Director = true,
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

Types.EventKind = {
	Enter = true,
	Exit = true,
	Begin = true,
	End = true,
	Activate = true,
	Deactivate = true,
	Enable = true,
	Disable = true,
	Acquire = true,
	Release = true,
	Register = true,
	Unregister = true,
	FutureEvent = true,
}

Types.GroupType = {
	Sequential = true,
	Parallel = true,
	Exclusive = true,
	Priority = true,
	FutureGroup = true,
}

Types.OutcomeKind = {
	Pending = true,
	Satisfied = true,
	Unsatisfied = true,
	Deferred = true,
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
	MaxTriggers = 700,
	MaxCategories = 500,
	MaxSources = 700,
	MaxTargets = 700,
	MaxEvents = 900,
	MaxFilters = 700,
	MaxConditions = 700,
	MaxDependencies = 900,
	MaxGroups = 600,
	MaxOutcomes = 700,
	MaxAudits = 500,
	MaxValidationFailures = 240,
	MaxSnapshotHistory = 80,
	MaxPayloadDepth = 9,
	MaxPayloadNodes = 460,
	MaxPayloadStringLength = 700,
	MaxTagsPerSchema = 32,
	MaxTriggerCategories = 80,
	MaxTriggerSources = 120,
	MaxTriggerTargets = 120,
	MaxTriggerEvents = 120,
	MaxTriggerFilters = 120,
	MaxTriggerConditions = 120,
	MaxTriggerDependencies = 120,
	MaxTriggerOutcomes = 100,
	MaxGroupMembers = 160,
	MaxAuditFindings = 96,
}

return Types

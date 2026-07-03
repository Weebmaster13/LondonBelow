--!strict
-- Shared constants and runtime limits for Phase 42 Condition Runtime Foundation.

local Types = {}

Types.Mode = "ServerAuthoritativeConditionSchemaRuntime"

Types.SchemaType = {
	ConditionDefinitionSchema = "ConditionDefinitionSchema",
	ConditionCategorySchema = "ConditionCategorySchema",
	ConditionExpressionSchema = "ConditionExpressionSchema",
	ConditionOperandSchema = "ConditionOperandSchema",
	ConditionOperatorSchema = "ConditionOperatorSchema",
	ConditionGroupSchema = "ConditionGroupSchema",
	ConditionDependencySchema = "ConditionDependencySchema",
	ConditionStateSchema = "ConditionStateSchema",
	ConditionOutcomeSchema = "ConditionOutcomeSchema",
	ConditionAuditSchema = "ConditionAuditSchema",
	SystemConditionSchema = "SystemConditionSchema",
}

Types.Domain = {
	Core = true,
	Gameplay = true,
	Observation = true,
	Director = true,
	Monster = true,
	MonsterAI = true,
	RuleEngine = true,
	Narrative = true,
	Presentation = true,
	Puzzle = true,
	Interaction = true,
	Inventory = true,
	World = true,
	Objective = true,
	Session = true,
	Persistence = true,
	Security = true,
	Accessibility = true,
	Performance = true,
	Localization = true,
	ContentRegistry = true,
	Chapter = true,
	System = true,
	Future = true,
}

Types.OperatorKind = {
	Equals = true,
	NotEquals = true,
	GreaterThan = true,
	LessThan = true,
	GreaterOrEqual = true,
	LessOrEqual = true,
	Exists = true,
	Missing = true,
	Contains = true,
	NotContains = true,
	Boolean = true,
	Logical = true,
	FutureOperator = true,
}

Types.GroupType = {
	AND = true,
	OR = true,
	NOT = true,
	Exclusive = true,
	FutureGroup = true,
}

Types.OutcomeKind = {
	Pass = true,
	Fail = true,
	Unknown = true,
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
	MaxConditions = 700,
	MaxCategories = 500,
	MaxExpressions = 900,
	MaxOperands = 900,
	MaxOperators = 500,
	MaxGroups = 600,
	MaxDependencies = 900,
	MaxStates = 700,
	MaxOutcomes = 700,
	MaxAudits = 500,
	MaxValidationFailures = 240,
	MaxSnapshotHistory = 80,
	MaxPayloadDepth = 9,
	MaxPayloadNodes = 460,
	MaxPayloadStringLength = 700,
	MaxTagsPerSchema = 32,
	MaxExpressionOperands = 120,
	MaxGroupConditions = 160,
	MaxConditionCategories = 80,
	MaxConditionExpressions = 120,
	MaxConditionDependencies = 120,
	MaxConditionOutcomes = 100,
	MaxAuditFindings = 96,
}

return Types

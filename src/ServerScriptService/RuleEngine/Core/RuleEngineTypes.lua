--!strict
-- Shared constants and runtime limits for Phase 41 Rule Engine Foundation.

local Types = {}

Types.Mode = "ServerAuthoritativeRuleEngineSchemaRuntime"

Types.SchemaType = {
	RuleDefinitionSchema = "RuleDefinitionSchema",
	RuleCategorySchema = "RuleCategorySchema",
	RulePredicateSchema = "RulePredicateSchema",
	RuleConstraintSchema = "RuleConstraintSchema",
	RulePermissionSchema = "RulePermissionSchema",
	RulePolicySchema = "RulePolicySchema",
	RuleGroupSchema = "RuleGroupSchema",
	RuleDependencySchema = "RuleDependencySchema",
	RuleOutcomeSchema = "RuleOutcomeSchema",
	RuleAuditSchema = "RuleAuditSchema",
	SystemRuleEngineSchema = "SystemRuleEngineSchema",
}

Types.RuleDomain = {
	Core = true,
	Governance = true,
	Runtime = true,
	Lifecycle = true,
	Scheduler = true,
	EventGraph = true,
	Observation = true,
	Director = true,
	Horror = true,
	AI = true,
	Monster = true,
	Gameplay = true,
	Physical = true,
	Presentation = true,
	Interaction = true,
	Puzzle = true,
	Inventory = true,
	World = true,
	Objective = true,
	Session = true,
	Persistence = true,
	DeveloperTools = true,
	Analytics = true,
	Accessibility = true,
	Performance = true,
	Security = true,
	Localization = true,
	ContentRegistry = true,
	Chapter = true,
	System = true,
	Future = true,
}

Types.RuleKind = {
	InvariantRule = true,
	ConstraintRule = true,
	PermissionRule = true,
	PolicyRule = true,
	PredicateRule = true,
	CompatibilityRule = true,
	SafetyRule = true,
	GovernanceRule = true,
	FutureRule = true,
}

Types.PredicateKind = {
	BooleanPredicate = true,
	ComparisonPredicate = true,
	MembershipPredicate = true,
	StatePredicate = true,
	DependencyPredicate = true,
	EventPredicate = true,
	FuturePredicate = true,
}

Types.ConstraintKind = {
	RequiredConstraint = true,
	ForbiddenConstraint = true,
	BoundedConstraint = true,
	CompatibilityConstraint = true,
	OwnershipConstraint = true,
	SafetyConstraint = true,
	FutureConstraint = true,
}

Types.PermissionKind = {
	AllowPermission = true,
	DenyPermission = true,
	RequireApprovalPermission = true,
	ReadOnlyPermission = true,
	SchemaOnlyPermission = true,
	FuturePermission = true,
}

Types.PolicyKind = {
	ValidationPolicy = true,
	GovernancePolicy = true,
	SafetyPolicy = true,
	CompatibilityPolicy = true,
	RuntimePolicy = true,
	FuturePolicy = true,
}

Types.OutcomeKind = {
	PassOutcome = true,
	FailOutcome = true,
	WarningOutcome = true,
	BlockedOutcome = true,
	DeferredOutcome = true,
	UnknownOutcome = true,
	FutureOutcome = true,
}

Types.DependencyKind = {
	Requires = true,
	Blocks = true,
	ConflictsWith = true,
	SoftOrder = true,
	CompatibleWith = true,
	FutureDependency = true,
}

Types.Limits = {
	MaxRules = 700,
	MaxCategories = 500,
	MaxPredicates = 800,
	MaxConstraints = 800,
	MaxPermissions = 700,
	MaxPolicies = 700,
	MaxGroups = 500,
	MaxDependencies = 900,
	MaxOutcomes = 700,
	MaxAudits = 500,
	MaxValidationFailures = 240,
	MaxSnapshotHistory = 80,
	MaxPayloadDepth = 9,
	MaxPayloadNodes = 460,
	MaxPayloadStringLength = 700,
	MaxTagsPerSchema = 32,
	MaxRuleCategories = 80,
	MaxRulePredicates = 100,
	MaxRuleConstraints = 100,
	MaxRulePermissions = 100,
	MaxRulePolicies = 100,
	MaxRuleDependencies = 120,
	MaxRuleOutcomes = 100,
	MaxGroupRules = 160,
	MaxAuditFindings = 96,
}

return Types

--!strict
-- Shared constants for Phase 37 Runtime Dependency Graph Foundation.

local Types = {}

Types.Mode = "ServerAuthoritativeRuntimeGraphSchemaRuntime"

Types.SchemaType = {
	RuntimeNodeSchema = "RuntimeNodeSchema",
	RuntimeDependencySchema = "RuntimeDependencySchema",
	RuntimeCapabilitySchema = "RuntimeCapabilitySchema",
	RuntimeRequirementSchema = "RuntimeRequirementSchema",
	RuntimeCompatibilitySchema = "RuntimeCompatibilitySchema",
	RuntimeOrderingSchema = "RuntimeOrderingSchema",
	RuntimeStartupPlanSchema = "RuntimeStartupPlanSchema",
	RuntimeShutdownPlanSchema = "RuntimeShutdownPlanSchema",
	RuntimeGroupSchema = "RuntimeGroupSchema",
	RuntimeGraphValidationSchema = "RuntimeGraphValidationSchema",
	SystemRuntimeGraphSchema = "SystemRuntimeGraphSchema",
}

Types.RuntimeLayer = {
	Core = true,
	Governance = true,
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
	RuntimeGraph = true,
	Chapter = true,
	Tooling = true,
	System = true,
}

Types.DependencyKind = {
	Required = true,
	Optional = true,
	Soft = true,
	DiagnosticOnly = true,
	SnapshotOnly = true,
	GovernanceOnly = true,
	FutureAdapter = true,
	Forbidden = true,
	Superseded = true,
	Historical = true,
}

Types.OrderingKind = {
	Before = true,
	After = true,
	SamePhase = true,
	Independent = true,
	Deferred = true,
	FutureOnly = true,
}

Types.CompatibilityKind = {
	Compatible = true,
	RequiresVersion = true,
	Deprecated = true,
	Incompatible = true,
	FutureCompatible = true,
	Unknown = true,
}

Types.ResultCode = {
	Ok = "Ok",
	InvalidRequest = "InvalidRequest",
	DuplicateNode = "DuplicateNode",
	DuplicateDependency = "DuplicateDependency",
	DuplicateCapability = "DuplicateCapability",
	DuplicateRequirement = "DuplicateRequirement",
	DuplicateCompatibility = "DuplicateCompatibility",
	DuplicateOrdering = "DuplicateOrdering",
	DuplicateStartupPlan = "DuplicateStartupPlan",
	DuplicateShutdownPlan = "DuplicateShutdownPlan",
	DuplicateGroup = "DuplicateGroup",
	DuplicateValidationRecord = "DuplicateValidationRecord",
	UnsafePayload = "UnsafePayload",
}

Types.Limits = {
	MaxRuntimeNodes = 500,
	MaxDependencies = 1200,
	MaxCapabilities = 900,
	MaxRequirements = 900,
	MaxCompatibilityRecords = 900,
	MaxOrderingRecords = 900,
	MaxStartupPlans = 250,
	MaxShutdownPlans = 250,
	MaxGroups = 350,
	MaxValidationRecords = 300,
	MaxValidationFailures = 220,
	MaxSnapshotHistory = 80,
	MaxPayloadDepth = 9,
	MaxPayloadNodes = 420,
	MaxPayloadStringLength = 640,
	MaxTagsPerSchema = 32,
	MaxPlanNodes = 128,
	MaxGroupNodes = 128,
	MaxPlanDependencies = 128,
	MaxPlanOrderings = 128,
}

return Types

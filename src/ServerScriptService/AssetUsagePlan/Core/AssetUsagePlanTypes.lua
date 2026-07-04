--!strict

local Types = {}

Types.Mode = "ServerAuthoritativeAssetUsagePlanSchemaRuntime"

Types.SchemaType = {
	UsagePlanDefinition = "UsagePlanDefinition",
	UsagePlanContext = "UsagePlanContext",
	UsagePlanConstraint = "UsagePlanConstraint",
	UsagePlanDependency = "UsagePlanDependency",
	UsagePlanBudget = "UsagePlanBudget",
	UsagePlanAccessibility = "UsagePlanAccessibility",
	UsagePlanAudit = "UsagePlanAudit",
	SystemUsagePlanSchema = "SystemUsagePlanSchema",
}

Types.UsageDomain = {
	Core = true,
	World = true,
	Room = true,
	Building = true,
	Environment = true,
	Character = true,
	Monster = true,
	NPC = true,
	Item = true,
	Inventory = true,
	Puzzle = true,
	Interaction = true,
	Objective = true,
	Narrative = true,
	Presentation = true,
	Audio = true,
	Lighting = true,
	Camera = true,
	VFX = true,
	UI = true,
	Animation = true,
	Localization = true,
	Accessibility = true,
	Performance = true,
	Security = true,
	DeveloperTools = true,
	ContentRegistry = true,
	Chapter = true,
	System = true,
	Future = true,
}

Types.UsageKind = {
	ReferencedOnly = true,
	VisualIntent = true,
	AudioIntent = true,
	AnimationIntent = true,
	InterfaceIntent = true,
	EnvironmentIntent = true,
	NarrativeIntent = true,
	AccessibilityIntent = true,
	PerformanceIntent = true,
	FutureIntent = true,
}

Types.ContextKind = {
	GlobalContext = true,
	ChapterContext = true,
	RoomContext = true,
	PlatformContext = true,
	QualityContext = true,
	AccessibilityContext = true,
	PerformanceContext = true,
	FutureContext = true,
}

Types.ConstraintKind = {
	SafetyConstraint = true,
	PerformanceConstraint = true,
	AccessibilityConstraint = true,
	ContentConstraint = true,
	MemoryConstraint = true,
	NetworkConstraint = true,
	FutureConstraint = true,
}

Types.DependencyKind = {
	RequiresPlan = true,
	SoftRequiresPlan = true,
	ConflictsWithPlan = true,
	ReplacesPlan = true,
	FutureDependency = true,
}

Types.BudgetKind = {
	MemoryBudget = true,
	DownloadBudget = true,
	InstanceBudget = true,
	AudioBudget = true,
	TextureBudget = true,
	AnimationBudget = true,
	UIPerformanceBudget = true,
	FutureBudget = true,
}

Types.AccessibilityKind = {
	ReducedMotion = true,
	ReducedFlashing = true,
	SubtitleSupport = true,
	CaptionSupport = true,
	ReadableText = true,
	ColorSafety = true,
	AudioAlternative = true,
	FutureAccessibility = true,
}

Types.AuditKind = {
	DesignReview = true,
	SafetyReview = true,
	PerformanceReview = true,
	AccessibilityReview = true,
	ProductionReview = true,
	FutureReview = true,
}

Types.Severity = {
	Info = true,
	Low = true,
	Medium = true,
	High = true,
	Critical = true,
}

Types.Priority = {
	Low = true,
	Normal = true,
	High = true,
	Critical = true,
}

Types.Limits = {
	MaxUsagePlans = 900,
	MaxContexts = 900,
	MaxConstraints = 900,
	MaxDependencies = 900,
	MaxBudgets = 700,
	MaxAccessibilityRecords = 700,
	MaxAudits = 500,
	MaxValidationFailures = 240,
	MaxSnapshotHistory = 60,
	MaxPayloadDepth = 8,
	MaxPayloadNodes = 450,
	MaxStringLength = 280,
	MaxTags = 32,
	MaxAuditFindings = 40,
	MaxPlanChildren = 160,
}

return Types

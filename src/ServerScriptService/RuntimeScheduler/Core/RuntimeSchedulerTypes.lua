--!strict
-- Shared type constants and runtime limits for Phase 39 Runtime Scheduler Foundation.

local Types = {}

Types.Mode = "ServerAuthoritativeRuntimeSchedulerSchemaRuntime"

Types.SchemaType = {
	SchedulePlanSchema = "SchedulePlanSchema",
	ScheduleSlotSchema = "ScheduleSlotSchema",
	ScheduleQueueSchema = "ScheduleQueueSchema",
	SchedulePrioritySchema = "SchedulePrioritySchema",
	ScheduleBudgetSchema = "ScheduleBudgetSchema",
	ScheduleDeadlineSchema = "ScheduleDeadlineSchema",
	ScheduleRetrySchema = "ScheduleRetrySchema",
	ScheduleIntervalSchema = "ScheduleIntervalSchema",
	ScheduleWindowSchema = "ScheduleWindowSchema",
	ScheduleDependencySchema = "ScheduleDependencySchema",
	ScheduleAuditSchema = "ScheduleAuditSchema",
	SystemRuntimeSchedulerSchema = "SystemRuntimeSchedulerSchema",
}

Types.ScheduleKind = {
	ImmediateSchema = true,
	DeferredSchema = true,
	IntervalSchema = true,
	WindowedSchema = true,
	PrioritySchema = true,
	BudgetedSchema = true,
	RetrySchema = true,
	DeadlineSchema = true,
	DependencySchema = true,
	FutureOnlySchema = true,
}

Types.QueueKind = {
	RuntimeQueue = true,
	DiagnosticQueue = true,
	SnapshotQueue = true,
	ValidationQueue = true,
	PresentationQueue = true,
	GameplayQueue = true,
	PersistenceQueue = true,
	ToolingQueue = true,
	FutureQueue = true,
}

Types.PriorityKind = {
	Critical = true,
	High = true,
	Normal = true,
	Low = true,
	Background = true,
	Deferred = true,
	FutureOnly = true,
}

Types.BudgetKind = {
	TimeBudget = true,
	CountBudget = true,
	MemoryBudget = true,
	NetworkBudget = true,
	FrameBudget = true,
	ValidationBudget = true,
	DiagnosticBudget = true,
	FutureBudget = true,
}

Types.DeadlineKind = {
	SoftDeadline = true,
	HardDeadline = true,
	ExpirationDeadline = true,
	ReviewDeadline = true,
	FutureDeadline = true,
}

Types.RetryKind = {
	NoRetry = true,
	ManualRetry = true,
	FixedGapRetry = true,
	ExponentialBackoffSchema = true,
	BoundedRetrySchema = true,
	FutureRetry = true,
}

Types.WindowKind = {
	AlwaysOpen = true,
	RuntimePhaseWindow = true,
	LifecycleWindow = true,
	TimeWindowSchema = true,
	BudgetWindow = true,
	FutureWindow = true,
}

Types.DependencyKind = {
	After = true,
	Before = true,
	Requires = true,
	Blocks = true,
	SoftOrder = true,
	FutureDependency = true,
}

Types.Limits = {
	MaxSchedulePlans = 600,
	MaxSlots = 900,
	MaxQueues = 400,
	MaxPriorities = 400,
	MaxBudgets = 500,
	MaxDeadlines = 500,
	MaxRetries = 500,
	MaxIntervals = 500,
	MaxWindows = 500,
	MaxDependencies = 900,
	MaxAudits = 500,
	MaxValidationFailures = 220,
	MaxSnapshotHistory = 80,
	MaxPayloadDepth = 9,
	MaxPayloadNodes = 420,
	MaxPayloadStringLength = 640,
	MaxTagsPerSchema = 32,
	MaxPlanQueues = 80,
	MaxPlanSlots = 120,
	MaxPlanBudgets = 80,
	MaxPlanDeadlines = 80,
	MaxPlanRetries = 80,
	MaxPlanIntervals = 80,
	MaxPlanWindows = 80,
	MaxPlanDependencies = 120,
	MaxAuditFindings = 96,
}

return Types

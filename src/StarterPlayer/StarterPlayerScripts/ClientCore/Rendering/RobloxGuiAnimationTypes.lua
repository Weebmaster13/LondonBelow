--!strict

local Types = {}

Types.SchemaVersion = "1.0.0"
Types.RuntimeVersion = "192.1.0"
Types.State = table.freeze({
	Idle = "Idle",
	Playing = "Playing",
	Completed = "Completed",
	Cancelled = "Cancelled",
	Failed = "Failed",
	Shutdown = "Shutdown",
})
Types.MotionPreference = table.freeze({ Full = "Full", Reduce = "Reduce", Remove = "Remove" })
Types.FailureType = table.freeze({
	RuntimeShutdown = "GuiAnimationRuntimeShutdown",
	InvalidContract = "InvalidGuiAnimationContract",
	InvalidTarget = "InvalidGuiAnimationTarget",
	InvalidRevision = "InvalidGuiAnimationRevision",
	UnsupportedProperty = "UnsupportedGuiAnimationProperty",
	InvalidGoal = "InvalidGuiAnimationGoal",
	BudgetExceeded = "GuiAnimationBudgetExceeded",
	DuplicateAnimation = "DuplicateGuiAnimation",
	TweenCreationFailed = "GuiAnimationTweenCreationFailed",
	ImmediateApplyFailed = "GuiAnimationImmediateApplyFailed",
	UnknownAnimation = "UnknownGuiAnimation",
	InvalidMotionPreference = "InvalidMotionPreference",
})
Types.Limits = table.freeze({
	maxActiveAnimations = 64,
	maxGoalsPerAnimation = 12,
	maxDurationSeconds = 30,
	maxDelaySeconds = 5,
	maxRepeatCount = 10,
	maxIdentifierLength = 128,
	maxAudit = 1024,
	maxFailures = 256,
	reducedDurationSeconds = 0.08,
	essentialRemovedDurationSeconds = 0.1,
})

return table.freeze(Types)

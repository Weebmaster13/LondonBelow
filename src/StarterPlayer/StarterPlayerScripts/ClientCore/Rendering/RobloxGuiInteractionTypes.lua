--!strict

local Types = {}

Types.RuntimeVersion = "188.1.0"
Types.RuntimeState = table.freeze({
	Unconfigured = "Unconfigured",
	Ready = "Ready",
	Mounted = "Mounted",
	Shutdown = "Shutdown",
})
Types.FailureType = table.freeze({
	RuntimeShutdown = "RuntimeShutdown",
	MountTargetInvalid = "MountTargetInvalid",
	InvalidActionId = "InvalidActionId",
	DuplicateAction = "DuplicateAction",
	UnknownAction = "UnknownAction",
	InvalidCallback = "InvalidCallback",
	InvalidAccessibilityMetadata = "InvalidAccessibilityMetadata",
	NonInteractiveAction = "NonInteractiveAction",
	DisabledControl = "DisabledControl",
	CallbackFailed = "CallbackFailed",
	FocusRestoreFailed = "FocusRestoreFailed",
})
Types.Limits = table.freeze({
	maxActions = 256,
	maxControls = 512,
	maxActionIdLength = 128,
	maxLabelLength = 256,
	maxDescriptionLength = 1024,
	maxFailures = 128,
	maxAuditRecords = 512,
})

return table.freeze(Types)

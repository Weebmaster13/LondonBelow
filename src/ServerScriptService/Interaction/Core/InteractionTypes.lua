--!strict
-- Shared constants for the server-authoritative Interaction Runtime.

local Types = {}

Types.Mode = "ServerAuthoritativeInteractionRuntime"
Types.RuntimeName = "InteractionRuntime"
Types.CoordinatorName = "InteractionCoordinator"

Types.SchemaVersion = 2

Types.InteractionType = {
	DoorInteractionSchema = "DoorInteractionSchema",
	DrawerInteractionSchema = "DrawerInteractionSchema",
	SwitchInteractionSchema = "SwitchInteractionSchema",
	ValveInteractionSchema = "ValveInteractionSchema",
	HandleInteractionSchema = "HandleInteractionSchema",
	LockInteractionSchema = "LockInteractionSchema",
	KeyholeInteractionSchema = "KeyholeInteractionSchema",
	InspectableInteractionSchema = "InspectableInteractionSchema",
	ReadableInteractionSchema = "ReadableInteractionSchema",
	PickupableInteractionSchema = "PickupableInteractionSchema",
	HidingSpotInteractionSchema = "HidingSpotInteractionSchema",
	PuzzleInteractionSchema = "PuzzleInteractionSchema",
	SystemInteractionSchema = "SystemInteractionSchema",
}

Types.ResultCode = {
	Ok = "Ok",
	InvalidRequest = "InvalidRequest",
	DuplicateInteraction = "DuplicateInteraction",
	DuplicateTarget = "DuplicateTarget",
	DuplicateRequest = "DuplicateRequest",
	UnknownInteraction = "UnknownInteraction",
	UnknownTarget = "UnknownTarget",
	UnsafePayload = "UnsafePayload",
	InvalidCooldown = "InvalidCooldown",
	InvalidLock = "InvalidLock",
	RateLimited = "RateLimited",
	NotEligible = "NotEligible",
	PermissionDenied = "PermissionDenied",
	ContentionBlocked = "ContentionBlocked",
	HandlerRejected = "HandlerRejected",
	Cancelled = "Cancelled",
	RuntimeUnavailable = "RuntimeUnavailable",
}

Types.InteractionStatus = {
	Registered = "Registered",
	Disabled = "Disabled",
	Deprecated = "Deprecated",
}

Types.TargetStatus = {
	Registered = "Registered",
	Unavailable = "Unavailable",
}

Types.EligibilityReason = {
	Eligible = "Eligible",
	Disabled = "Disabled",
	UnknownInteraction = "UnknownInteraction",
	UnknownTarget = "UnknownTarget",
	TargetMismatch = "TargetMismatch",
	CooldownActive = "CooldownActive",
	RateLimited = "RateLimited",
	ContentionActive = "ContentionActive",
	Unauthorized = "Unauthorized",
	UnsafeRequest = "UnsafeRequest",
	HandlerUnavailable = "HandlerUnavailable",
}

Types.SessionStatus = {
	Planned = "Planned",
	Authorized = "Authorized",
	Executing = "Executing",
	Completed = "Completed",
	Rejected = "Rejected",
	Cancelled = "Cancelled",
	Failed = "Failed",
}

Types.RequestKind = {
	Primary = "Primary",
	Secondary = "Secondary",
	Focus = "Focus",
	System = "System",
}

Types.Limits = {
	MaxInteractions = 500,
	MaxEligibilityRecords = 500,
	MaxIntentRecords = 260,
	MaxLocks = 260,
	MaxCooldowns = 260,
	MaxValidationFailures = 180,
	MaxSnapshotHistory = 80,
	MaxPayloadDepth = 8,
	MaxPayloadNodes = 260,
	MaxPayloadStringLength = 512,
	MaxTags = 24,
	MaxCooldownSeconds = 3600,
	MaxTargets = 500,
	MaxDefinitions = 500,
	MaxSessions = 260,
	MaxEvidenceRecords = 260,
	MaxRequestsPerPlayerWindow = 12,
	MaxRequestWindowSeconds = 4,
	MaxRequestIdLength = 160,
	MaxSessionIdLength = 180,
}

return Types

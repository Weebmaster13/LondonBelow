--!strict
-- Shared constants for Phase 23 Interaction Runtime Foundation.

local Types = {}

Types.Mode = "ServerAuthoritativeInteractionSchemaRuntime"

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
	UnknownInteraction = "UnknownInteraction",
	UnsafePayload = "UnsafePayload",
	InvalidCooldown = "InvalidCooldown",
	InvalidLock = "InvalidLock",
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
}

return Types

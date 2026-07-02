--!strict
-- Shared constants for Phase 25 Inventory Runtime Foundation.

local Types = {}

Types.Mode = "ServerAuthoritativeInventorySchemaRuntime"

Types.ProfileKind = {
	InventoryProfileSchema = "InventoryProfileSchema",
	SystemInventorySchema = "SystemInventorySchema",
}

Types.ItemType = {
	InventoryItemSchema = "InventoryItemSchema",
	InventorySlotSchema = "InventorySlotSchema",
	InventoryCapacitySchema = "InventoryCapacitySchema",
	InventoryOwnershipSchema = "InventoryOwnershipSchema",
	InventoryEligibilitySchema = "InventoryEligibilitySchema",
	ItemStateSchema = "ItemStateSchema",
	SystemInventorySchema = "SystemInventorySchema",
}

Types.ResultCode = {
	Ok = "Ok",
	InvalidRequest = "InvalidRequest",
	DuplicateProfile = "DuplicateProfile",
	DuplicateItem = "DuplicateItem",
	UnknownProfile = "UnknownProfile",
	UnsafePayload = "UnsafePayload",
}

Types.Limits = {
	MaxProfiles = 260,
	MaxItems = 800,
	MaxSlotsPerProfile = 80,
	MaxValidationFailures = 180,
	MaxSnapshotHistory = 80,
	MaxPayloadDepth = 8,
	MaxPayloadNodes = 280,
	MaxPayloadStringLength = 512,
	MaxTags = 24,
	MaxCapacity = 200,
}

return Types

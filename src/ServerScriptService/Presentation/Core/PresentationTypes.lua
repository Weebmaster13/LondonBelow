--!strict
-- Shared constants for Phase 22 Presentation Runtime Foundation.

local Types = {}

Types.Mode = "ServerAuthoritativePresentationSchemaRuntime"

Types.PresentationType = {
	UIPlan = "UIPlan",
	AudioPlan = "AudioPlan",
	LightingPlan = "LightingPlan",
	CameraPlan = "CameraPlan",
	VFXPlan = "VFXPlan",
	AccessibilityPlan = "AccessibilityPlan",
	SystemPresentationPlan = "SystemPresentationPlan",
}

Types.ChannelType = {
	UI = "UI",
	Audio = "Audio",
	Lighting = "Lighting",
	Camera = "Camera",
	VFX = "VFX",
	Accessibility = "Accessibility",
	System = "System",
}

Types.Status = {
	Pending = "Pending",
	Approved = "Approved",
	Rejected = "Rejected",
	Expired = "Expired",
	Queued = "Queued",
	Routed = "Routed",
	Recorded = "Recorded",
}

Types.ResultCode = {
	Ok = "Ok",
	InvalidRequest = "InvalidRequest",
	DuplicatePresentation = "DuplicatePresentation",
	DuplicateApproval = "DuplicateApproval",
	MissingApproval = "MissingApproval",
	MissingChannel = "MissingChannel",
	InvalidChannel = "InvalidChannel",
	Expired = "Expired",
	UnsupportedPresentationType = "UnsupportedPresentationType",
	UnsafePayload = "UnsafePayload",
	QueueFull = "QueueFull",
}

Types.Limits = {
	MaxRequests = 260,
	MaxQueue = 180,
	MaxApprovalsPerRequest = 12,
	MaxChannelsPerRequest = 12,
	MaxRoutingRecords = 260,
	MaxValidationFailures = 180,
	MaxSnapshotHistory = 80,
	MaxPayloadDepth = 8,
	MaxPayloadNodes = 260,
	MaxPayloadStringLength = 512,
	MaxPriority = 100,
	DefaultExpirationSeconds = 30,
}

return Types

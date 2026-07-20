--!strict
-- Shared constants for Phase 22 Presentation Runtime Foundation.

local Types = {}

Types.Mode = "ServerAuthoritativePresentationSchemaRuntime"
Types.RuntimeName = "PresentationRuntime"
Types.ProviderName = "presentationRuntime"

Types.PresentationType = {
	UIPlan = "UIPlan",
	AudioPlan = "AudioPlan",
	LightingPlan = "LightingPlan",
	CameraPlan = "CameraPlan",
	VFXPlan = "VFXPlan",
	AccessibilityPlan = "AccessibilityPlan",
	SystemPresentationPlan = "SystemPresentationPlan",
	ShowPrompt = "ShowPrompt",
	HidePrompt = "HidePrompt",
	UpdatePrompt = "UpdatePrompt",
	ShowInteractionBusy = "ShowInteractionBusy",
	HideInteractionBusy = "HideInteractionBusy",
	PlayAudio = "PlayAudio",
	StopAudio = "StopAudio",
	PlayAnimation = "PlayAnimation",
	StopAnimation = "StopAnimation",
	UpdateCursor = "UpdateCursor",
	ShowMessage = "ShowMessage",
	HideMessage = "HideMessage",
	HighlightObject = "HighlightObject",
	RemoveHighlight = "RemoveHighlight",
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
	DuplicateCommand = "DuplicateCommand",
	InvalidCommand = "InvalidCommand",
	InvalidPrompt = "InvalidPrompt",
	ExpiredCommand = "ExpiredCommand",
}

Types.CommandPriority = {
	Critical = 500,
	Interaction = 400,
	Inspection = 300,
	Context = 200,
	Ambient = 100,
}

Types.CursorState = {
	Default = "default",
	Interactable = "interactable",
	Busy = "busy",
	Disabled = "disabled",
	Inspecting = "inspecting",
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
	MaxCommands = 260,
	MaxExecutedCommands = 260,
	MaxExpiredCommands = 180,
	MaxPrompts = 80,
	MaxBusyStates = 80,
	MaxAudioRequests = 120,
	MaxAnimationRequests = 120,
	MaxMessageRequests = 120,
	MaxCursorStates = 80,
	MaxHighlights = 80,
	MaxEvidence = 260,
}

return Types

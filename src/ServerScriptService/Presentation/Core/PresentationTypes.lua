--!strict
-- Shared constants for Phase 22 Presentation Runtime Foundation.

local Types = {}

Types.Mode = "ServerAuthoritativePresentationSchemaRuntime"
Types.RuntimeName = "PresentationRuntime"
Types.ProviderName = "presentationRuntime"
Types.CapabilityId = "presentationRuntimeCapability"

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
	MaxRuntimeSessions = 320,
	MaxRuntimeConsumers = 48,
	MaxRuntimeQueuedSessions = 240,
	MaxRuntimeAcknowledgements = 520,
	MaxRuntimeSynchronizationRecords = 520,
	MaxRuntimeProfilerRecords = 240,
}

Types.RuntimeSessionState = {
	Created = "Created",
	Queued = "Queued",
	Assigned = "Assigned",
	Preparing = "Preparing",
	Ready = "Ready",
	Acknowledged = "Acknowledged",
	Completed = "Completed",
	Closed = "Closed",
	Cancelled = "Cancelled",
	Expired = "Expired",
	Failed = "Failed",
	Suspended = "Suspended",
}

Types.RuntimeConsumerStatus = {
	Registered = "Registered",
	Available = "Available",
	Suspended = "Suspended",
	Disabled = "Disabled",
}

Types.RuntimeAcknowledgementKind = {
	Accepted = "Accepted",
	Started = "Started",
	Completed = "Completed",
	Cancelled = "Cancelled",
	Failed = "Failed",
	Expired = "Expired",
}

Types.RuntimeFailureType = {
	RuntimeShutdown = "RuntimeShutdown",
	ValidationFailure = "ValidationFailure",
	DuplicateSession = "DuplicateSession",
	UnknownSession = "UnknownSession",
	DuplicateConsumer = "DuplicateConsumer",
	UnknownConsumer = "UnknownConsumer",
	InvalidConsumer = "InvalidConsumer",
	InvalidLifecycleTransition = "InvalidLifecycleTransition",
	QueueOverflow = "QueueOverflow",
	InvalidSynchronization = "InvalidSynchronization",
	DuplicateAcknowledgement = "DuplicateAcknowledgement",
	LimitExceeded = "LimitExceeded",
}

local function contains(values: { [string]: string }, value: string): boolean
	for _, item in pairs(values) do
		if item == value then
			return true
		end
	end
	return false
end

function Types.isRuntimeSessionState(value: string): boolean
	return contains(Types.RuntimeSessionState, value)
end

function Types.isRuntimeAcknowledgementKind(value: string): boolean
	return contains(Types.RuntimeAcknowledgementKind, value)
end

return Types

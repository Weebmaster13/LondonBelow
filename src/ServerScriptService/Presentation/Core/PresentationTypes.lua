--!strict
-- Shared constants for Phase 22 Presentation Runtime Foundation.

local Types = {}

Types.Mode = "ServerAuthoritativePresentationSchemaRuntime"
Types.RuntimeName = "PresentationRuntime"
Types.ProviderName = "presentationRuntime"
Types.CapabilityId = "presentationRuntimeCapability"
Types.ExecutionProviderName = "presentationRuntimeExecution"
Types.ExecutionRuntimeId = "presentationRuntimeExecution"
Types.RenderingContractId = "presentationRenderingContract"
Types.RenderingContractProviderName = "presentationRuntimeRenderingContract"
Types.RenderingContractSnapshotProviderName = "presentationRuntimeRenderingContract"
Types.RenderingRuntimeProviderName = "presentationRenderingRuntime"
Types.RenderingRuntimeCapabilityId = "presentationRenderingRuntimeCapability"
Types.RenderingRuntimeId = "presentationRenderingRuntime"

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

Types.ExecutionSchedulerState = {
	Idle = "Idle",
	Scheduling = "Scheduling",
	Executing = "Executing",
	Suspended = "Suspended",
	Recovering = "Recovering",
	Shutdown = "Shutdown",
}

Types.ExecutionState = {
	Created = "Created",
	Queued = "Queued",
	Assigned = "Assigned",
	Preparing = "Preparing",
	Executing = "Executing",
	WaitingForAcknowledgement = "WaitingForAcknowledgement",
	Acknowledged = "Acknowledged",
	Completed = "Completed",
	Closed = "Closed",
	Cancelled = "Cancelled",
	Expired = "Expired",
	Failed = "Failed",
	Suspended = "Suspended",
}

Types.ExecutionFailureType = {
	RuntimeShutdown = "RuntimeShutdown",
	InvalidExecution = "InvalidExecution",
	InvalidLifecycleTransition = "InvalidLifecycleTransition",
	InvalidAcknowledgement = "InvalidAcknowledgement",
	QueueOverflow = "QueueOverflow",
	UnknownExecution = "UnknownExecution",
	UnknownSession = "UnknownSession",
	SynchronizationFailure = "SynchronizationFailure",
	LimitExceeded = "LimitExceeded",
	ValidationFailure = "ValidationFailure",
	DuplicateExecution = "DuplicateExecution",
	DuplicateAcknowledgement = "DuplicateAcknowledgement",
}

Types.ExecutionLimits = {
	MaxActiveExecutions = 320,
	MaxQueuedExecutions = 240,
	MaxSuspendedExecutions = 160,
	MaxExecutionAcknowledgements = 520,
	MaxExecutionSynchronizationRecords = 520,
	MaxExecutionEvidence = 900,
	MaxExecutionProfilerRecords = 240,
}

Types.RenderingKind = {
	DialogueLine = "DialogueLine",
	DialogueChoiceList = "DialogueChoiceList",
	Narration = "Narration",
	SpeakerIntroduction = "SpeakerIntroduction",
	SystemMessage = "SystemMessage",
	ConversationTransition = "ConversationTransition",
	ConversationCompletion = "ConversationCompletion",
	Notification = "Notification",
	Menu = "Menu",
	Overlay = "Overlay",
	Prompt = "Prompt",
	Subtitle = "Subtitle",
	Caption = "Caption",
	HUDPlan = "HUDPlan",
	UIPlan = "UIPlan",
	CameraPlan = "CameraPlan",
	AnimationPlan = "AnimationPlan",
	AudioPlan = "AudioPlan",
	CompositePresentation = "CompositePresentation",
	PresentationCue = "PresentationCue",
}

Types.RenderingRequestStatus = {
	Created = "Created",
	Validated = "Validated",
	Registered = "Registered",
	PendingRenderer = "PendingRenderer",
	Accepted = "Accepted",
	Started = "Started",
	Completed = "Completed",
	Closed = "Closed",
	Rejected = "Rejected",
	Cancelled = "Cancelled",
	Expired = "Expired",
	Failed = "Failed",
}

Types.RendererCapabilityStatus = {
	Registered = "Registered",
	Available = "Available",
	Suspended = "Suspended",
	Disabled = "Disabled",
	Deprecated = "Deprecated",
	Unavailable = "Unavailable",
}

Types.RenderingAcknowledgementKind = {
	Accepted = "Accepted",
	Rejected = "Rejected",
	Assigned = "Assigned",
	Preparing = "Preparing",
	Ready = "Ready",
	Started = "Started",
	Completed = "Completed",
	Cancelled = "Cancelled",
	Failed = "Failed",
	Expired = "Expired",
	Closed = "Closed",
}

Types.RenderingSynchronizationPolicy = {
	NoWait = "NoWait",
	WaitForAccepted = "WaitForAccepted",
	WaitForAssigned = "WaitForAssigned",
	WaitForReady = "WaitForReady",
	WaitForStarted = "WaitForStarted",
	WaitForCompleted = "WaitForCompleted",
	WaitForCancelled = "WaitForCancelled",
	WaitForTerminalState = "WaitForTerminalState",
}

Types.RenderingContractFailureType = {
	RuntimeShutdown = "RuntimeShutdown",
	ValidationFailure = "ValidationFailure",
	DuplicateContract = "DuplicateContract",
	UnknownContract = "UnknownContract",
	DuplicateRenderingRequest = "DuplicateRenderingRequest",
	UnknownRenderingRequest = "UnknownRenderingRequest",
	InvalidRenderingRequest = "InvalidRenderingRequest",
	InvalidRenderingKind = "InvalidRenderingKind",
	InvalidDescriptor = "InvalidDescriptor",
	DescriptorTooLarge = "DescriptorTooLarge",
	UnsupportedContractVersion = "UnsupportedContractVersion",
	DuplicateRendererCapability = "DuplicateRendererCapability",
	UnknownRendererCapability = "UnknownRendererCapability",
	InvalidRendererCapability = "InvalidRendererCapability",
	RendererIncompatible = "RendererIncompatible",
	DuplicateAcknowledgement = "DuplicateAcknowledgement",
	UnknownAcknowledgement = "UnknownAcknowledgement",
	InvalidAcknowledgement = "InvalidAcknowledgement",
	OwnershipMismatch = "OwnershipMismatch",
	InvalidSynchronizationPolicy = "InvalidSynchronizationPolicy",
	SynchronizationFailure = "SynchronizationFailure",
	LimitExceeded = "LimitExceeded",
}

Types.RenderingContractLimits = {
	MaxRendererCapabilities = 48,
	MaxRenderingRequests = 320,
	MaxAcknowledgements = 520,
	MaxSynchronizationRecords = 520,
	MaxLocalizationReferences = 640,
	MaxAccessibilityReferences = 640,
	MaxAssetReferences = 960,
	MaxEvidence = 900,
	MaxProfilerRecords = 240,
	MaxDescriptorDepth = 8,
	MaxDescriptorFields = 128,
	MaxRuntimeMetadataFields = 64,
}

Types.RenderingRuntimeRendererStatus = {
	Registered = "Registered",
	Available = "Available",
	Busy = "Busy",
	Suspended = "Suspended",
	Disabled = "Disabled",
	Unavailable = "Unavailable",
	Shutdown = "Shutdown",
}

Types.RenderingRuntimeAssignmentState = {
	Pending = "Pending",
	Assigned = "Assigned",
	Suspended = "Suspended",
	Released = "Released",
	Cancelled = "Cancelled",
	Failed = "Failed",
}

Types.RenderingRuntimeLifecycleState = {
	Created = "Created",
	Validated = "Validated",
	PendingRenderer = "PendingRenderer",
	Assigned = "Assigned",
	Preparing = "Preparing",
	Ready = "Ready",
	Acknowledged = "Acknowledged",
	Completed = "Completed",
	Closed = "Closed",
	Failed = "Failed",
	Cancelled = "Cancelled",
	Expired = "Expired",
	Rejected = "Rejected",
}

Types.RenderingRuntimeAcknowledgementKind = {
	Accepted = "Accepted",
	Assigned = "Assigned",
	Preparing = "Preparing",
	Ready = "Ready",
	Started = "Started",
	Completed = "Completed",
	Cancelled = "Cancelled",
	Failed = "Failed",
	Expired = "Expired",
}

Types.RenderingRuntimeFailureType = {
	RuntimeShutdown = "RuntimeShutdown",
	ValidationFailure = "ValidationFailure",
	DuplicateRuntime = "DuplicateRuntime",
	DuplicateRenderer = "DuplicateRenderer",
	UnknownRenderer = "UnknownRenderer",
	DuplicateSession = "DuplicateSession",
	UnknownSession = "UnknownSession",
	InvalidRenderingRequest = "InvalidRenderingRequest",
	InvalidAssignment = "InvalidAssignment",
	InvalidLifecycleTransition = "InvalidLifecycleTransition",
	DuplicateAcknowledgement = "DuplicateAcknowledgement",
	OwnershipMismatch = "OwnershipMismatch",
	RendererUnavailable = "RendererUnavailable",
	RendererCapacityExceeded = "RendererCapacityExceeded",
	SynchronizationFailure = "SynchronizationFailure",
	LimitExceeded = "LimitExceeded",
}

Types.RenderingRuntimeLimits = {
	MaxRenderers = 48,
	MaxRenderingSessions = 320,
	MaxAssignments = 520,
	MaxAcknowledgements = 520,
	MaxSynchronizationRecords = 520,
	MaxEvidence = 900,
	MaxProfilerRecords = 240,
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

function Types.isExecutionState(value: string): boolean
	return contains(Types.ExecutionState, value)
end

function Types.isRenderingKind(value: string): boolean
	return contains(Types.RenderingKind, value)
end

function Types.isRenderingRequestStatus(value: string): boolean
	return contains(Types.RenderingRequestStatus, value)
end

function Types.isRendererCapabilityStatus(value: string): boolean
	return contains(Types.RendererCapabilityStatus, value)
end

function Types.isRenderingAcknowledgementKind(value: string): boolean
	return contains(Types.RenderingAcknowledgementKind, value)
end

function Types.isRenderingSynchronizationPolicy(value: string): boolean
	return contains(Types.RenderingSynchronizationPolicy, value)
end

function Types.isRenderingRuntimeRendererStatus(value: string): boolean
	return contains(Types.RenderingRuntimeRendererStatus, value)
end

function Types.isRenderingRuntimeAssignmentState(value: string): boolean
	return contains(Types.RenderingRuntimeAssignmentState, value)
end

function Types.isRenderingRuntimeLifecycleState(value: string): boolean
	return contains(Types.RenderingRuntimeLifecycleState, value)
end

function Types.isRenderingRuntimeAcknowledgementKind(value: string): boolean
	return contains(Types.RenderingRuntimeAcknowledgementKind, value)
end

return Types

--!strict

local Types = {}

Types.ProviderName = "dialogueRuntimeInteraction"

Types.InteractionStatus = {
	Created = "Created",
	WaitingForResponse = "WaitingForResponse",
	ResponseReceived = "ResponseReceived",
	Validated = "Validated",
	Applied = "Applied",
	Completed = "Completed",
	Cancelled = "Cancelled",
	Expired = "Expired",
	Closed = "Closed",
}

Types.RuntimeEventKind = {
	InteractionCreated = "InteractionCreated",
	InteractionWaiting = "InteractionWaiting",
	InteractionValidated = "InteractionValidated",
	InteractionApplied = "InteractionApplied",
	InteractionCancelled = "InteractionCancelled",
	InteractionExpired = "InteractionExpired",
	InteractionResumed = "InteractionResumed",
	NestedConversationEntered = "NestedConversationEntered",
	NestedConversationExited = "NestedConversationExited",
}

Types.FailureType = {
	ValidationFailure = "ValidationFailure",
	DuplicateInteraction = "DuplicateInteraction",
	UnknownInteraction = "UnknownInteraction",
	DuplicateResponse = "DuplicateResponse",
	InvalidInteractionStatus = "InvalidInteractionStatus",
	InvalidResponse = "InvalidResponse",
	InvalidTimeout = "InvalidTimeout",
	InvalidInterruption = "InvalidInterruption",
	InvalidNestedConversation = "InvalidNestedConversation",
	RuntimeShutdown = "RuntimeShutdown",
	LimitExceeded = "LimitExceeded",
}

Types.Limits = {
	MaxPendingInteractions = 240,
	MaxNestedConversations = 32,
	MaxWaitingExecutions = 240,
	MaxRuntimeEvents = 520,
	MaxInterruptions = 96,
	MaxTimeoutRecords = 240,
	MaxEvidence = 760,
	MaxStringLength = 2048,
	MaxPayloadDepth = 8,
	MaxPayloadNodes = 360,
}

return Types

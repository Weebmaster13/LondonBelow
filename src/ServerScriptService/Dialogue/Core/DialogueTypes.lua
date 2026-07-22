--!strict

local Types = {}

Types.ProviderName = "dialogueRuntimeCapability"
Types.CapabilityId = "dialogue.runtimeCapability"

Types.ParticipantType = {
	Player = "Player",
	NPC = "NPC",
	Group = "Group",
	System = "System",
}

Types.NodeType = {
	Text = "Text",
	Choice = "Choice",
	Condition = "Condition",
	EventTrigger = "EventTrigger",
	VariableAssignment = "VariableAssignment",
	End = "End",
}

Types.ConversationState = {
	Created = "Created",
	Initialized = "Initialized",
	Active = "Active",
	Waiting = "Waiting",
	Transitioning = "Transitioning",
	Completed = "Completed",
	Closed = "Closed",
}

Types.FailureType = {
	ValidationFailure = "ValidationFailure",
	DuplicateDialogue = "DuplicateDialogue",
	DuplicateConversation = "DuplicateConversation",
	DuplicateParticipant = "DuplicateParticipant",
	UnknownDialogue = "UnknownDialogue",
	UnknownConversation = "UnknownConversation",
	UnknownParticipant = "UnknownParticipant",
	UnsupportedParticipantType = "UnsupportedParticipantType",
	UnsupportedNodeType = "UnsupportedNodeType",
	InvalidNodeGraph = "InvalidNodeGraph",
	InvalidLifecycleTransition = "InvalidLifecycleTransition",
	UnsafePayload = "UnsafePayload",
	DomainRegistrationFailed = "DomainRegistrationFailed",
	RuntimeShutdown = "RuntimeShutdown",
	LimitExceeded = "LimitExceeded",
}

Types.Limits = {
	MaxDialogueDefinitions = 120,
	MaxConversationInstances = 240,
	MaxParticipants = 240,
	MaxNodesPerDialogue = 120,
	MaxChoicesPerNode = 12,
	MaxVariablesPerDialogue = 64,
	MaxConditionsPerDialogue = 80,
	MaxEvidence = 640,
	MaxStringLength = 2048,
	MaxPayloadDepth = 8,
	MaxPayloadNodes = 320,
}

return Types

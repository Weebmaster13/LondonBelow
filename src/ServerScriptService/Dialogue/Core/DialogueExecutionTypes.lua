--!strict

local Types = {}

Types.ProviderName = "dialogueRuntimeExecution"

Types.ExecutionState = {
	Initializing = "Initializing",
	Executing = "Executing",
	WaitingChoice = "WaitingChoice",
	WaitingCondition = "WaitingCondition",
	Transitioning = "Transitioning",
	Completing = "Completing",
	Closed = "Closed",
}

Types.NodeExecutionType = {
	Text = "Text",
	Choice = "Choice",
	Condition = "Condition",
	Variable = "Variable",
	EventMetadata = "EventMetadata",
	End = "End",
}

Types.FailureType = {
	ValidationFailure = "ValidationFailure",
	DuplicateExecution = "DuplicateExecution",
	UnknownExecution = "UnknownExecution",
	UnknownConversation = "UnknownConversation",
	UnknownDialogue = "UnknownDialogue",
	UnknownNode = "UnknownNode",
	UnknownChoice = "UnknownChoice",
	InvalidExecutionState = "InvalidExecutionState",
	InvalidTraversal = "InvalidTraversal",
	InvalidVariableMutation = "InvalidVariableMutation",
	RuntimeShutdown = "RuntimeShutdown",
	LimitExceeded = "LimitExceeded",
}

Types.Limits = {
	MaxExecutionContexts = 240,
	MaxRuntimeVariables = 96,
	MaxTraversalHistory = 320,
	MaxEvidence = 720,
	MaxSchedulerQueue = 240,
	MaxStringLength = 2048,
	MaxPayloadDepth = 8,
	MaxPayloadNodes = 360,
}

return Types

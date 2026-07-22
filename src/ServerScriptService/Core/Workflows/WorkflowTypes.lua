--!strict

local Types = {}

Types.ProviderName = "runtimeWorkflowOrchestration"

Types.Category = {
	System = "System",
	Gameplay = "Gameplay",
	Narrative = "Narrative",
	Save = "Save",
	Background = "Background",
	Administrative = "Administrative",
}

Types.LifecycleState = {
	Created = "Created",
	Registered = "Registered",
	Validated = "Validated",
	Scheduled = "Scheduled",
	Running = "Running",
	Waiting = "Waiting",
	Completed = "Completed",
	Cancelled = "Cancelled",
	Failed = "Failed",
	Archived = "Archived",
}

Types.TransitionSource = {
	EventReceived = "EventReceived",
	QueryEvaluated = "QueryEvaluated",
	CommandAcknowledged = "CommandAcknowledged",
	Timeout = "Timeout",
	ExplicitCancellation = "ExplicitCancellation",
}

Types.WaitKind = {
	Event = "Event",
	QueryResult = "QueryResult",
	Timeout = "Timeout",
	ExternalApproval = "ExternalApproval",
}

Types.FailureType = {
	ValidationFailure = "ValidationFailure",
	DuplicateWorkflow = "DuplicateWorkflow",
	UnknownWorkflow = "UnknownWorkflow",
	DuplicateInstance = "DuplicateInstance",
	UnknownInstance = "UnknownInstance",
	InvalidLifecycleTransition = "InvalidLifecycleTransition",
	InvalidTransition = "InvalidTransition",
	InvalidState = "InvalidState",
	InvalidTransitionSource = "InvalidTransitionSource",
	InvalidCategory = "InvalidCategory",
	UnauthorizedCancellation = "UnauthorizedCancellation",
	TerminalInstanceMutation = "TerminalInstanceMutation",
	UnsafePayload = "UnsafePayload",
	QueueFull = "QueueFull",
}

Types.Limits = {
	MaxWorkflowDefinitions = 160,
	MaxActiveInstances = 240,
	MaxStatesPerWorkflow = 80,
	MaxTransitionsPerWorkflow = 160,
	MaxVariables = 80,
	MaxVariableDepth = 8,
	MaxVariableNodes = 220,
	MaxStringLength = 2048,
	MaxEvidence = 420,
	MaxHistory = 320,
	MaxConcurrentWaits = 240,
	MaxWorkflowDepth = 8,
}

return Types

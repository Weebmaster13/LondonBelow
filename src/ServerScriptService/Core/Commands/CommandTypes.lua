--!strict

local Types = {}

Types.ProviderName = "runtimeCommandBus"

Types.Priority = {
	Critical = "Critical",
	High = "High",
	Normal = "Normal",
	Low = "Low",
}

Types.PriorityRank = {
	Critical = 4,
	High = 3,
	Normal = 2,
	Low = 1,
}

Types.Status = {
	Created = "Created",
	Validated = "Validated",
	Queued = "Queued",
	Routing = "Routing",
	Executing = "Executing",
	Succeeded = "Succeeded",
	Cancelled = "Cancelled",
	Rejected = "Rejected",
	Failed = "Failed",
}

Types.ExecutionPolicy = {
	AuthoritativeSingleOwner = "AuthoritativeSingleOwner",
}

Types.IdempotencyPolicy = {
	RequireIdempotencyKey = "RequireIdempotencyKey",
	OptionalIdempotencyKey = "OptionalIdempotencyKey",
}

Types.FailureType = {
	ValidationFailure = "ValidationFailure",
	UnknownCommandType = "UnknownCommandType",
	UnknownRequester = "UnknownRequester",
	RequesterNotAuthorized = "RequesterNotAuthorized",
	UnknownHandler = "UnknownHandler",
	AmbiguousOwner = "AmbiguousOwner",
	InvalidPayload = "InvalidPayload",
	InvalidPriority = "InvalidPriority",
	QueueFull = "QueueFull",
	DuplicateCommandId = "DuplicateCommandId",
	DuplicateIdempotencyKey = "DuplicateIdempotencyKey",
	NoHandler = "NoHandler",
	CancellationRejected = "CancellationRejected",
	ExecutionFailure = "ExecutionFailure",
	ShutdownRejected = "ShutdownRejected",
}

Types.Limits = {
	MaxCommandTypes = 240,
	MaxRequesters = 160,
	MaxHandlers = 240,
	MaxQueueDepth = 240,
	MaxExecutionHistory = 240,
	MaxEvidence = 360,
	MaxPayloadDepth = 8,
	MaxPayloadNodes = 180,
	MaxStringLength = 2048,
	MaxBatchSize = 40,
}

Types.CoreCommandTypes = {
	Test = "core.command.test",
}

Types.SignalNames = {
	CommandSubmitted = "runtimeCommandBus.commandSubmitted",
	CommandValidated = "runtimeCommandBus.commandValidated",
	CommandQueued = "runtimeCommandBus.commandQueued",
	CommandRouting = "runtimeCommandBus.commandRouting",
	CommandExecuting = "runtimeCommandBus.commandExecuting",
	CommandSucceeded = "runtimeCommandBus.commandSucceeded",
	CommandRejected = "runtimeCommandBus.commandRejected",
	CommandCancelled = "runtimeCommandBus.commandCancelled",
	CommandFailed = "runtimeCommandBus.commandFailed",
}

return Types

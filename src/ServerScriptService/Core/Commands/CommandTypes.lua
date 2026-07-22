--!strict

local Types = {}

Types.ProviderName = "runtimeCommandBus"

export type CommandResult = {
	status: string,
	executionDuration: number,
	resultCode: string,
	output: any,
	diagnostics: any,
	evidenceReference: string,
}

export type CommandEnvelope = {
	commandId: string,
	commandType: string,
	schemaVersion: string,
	priority: string,
	requesterId: string,
	ownerRuntime: string,
	payload: any,
	metadata: any,
	correlationId: string,
	causationId: string,
	idempotencyKey: string?,
	creationTimestamp: number,
	admissionTimestamp: number?,
	scheduledTimestamp: number?,
	executionTimestamp: number?,
	completionTimestamp: number?,
	executionState: string,
	cancellationState: string,
	resultReference: string?,
	diagnosticsReference: string?,
	evidenceReference: string?,
	sequence: number,
	lifecycle: { any },
}

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
	Submitted = "Submitted",
	Validated = "Validated",
	Authorized = "Authorized",
	Queued = "Queued",
	Scheduled = "Scheduled",
	Executing = "Executing",
	Completed = "Completed",
	Cancelled = "Cancelled",
	Rejected = "Rejected",
	Failed = "Failed",
}

Types.ResultStatus = {
	Success = "Success",
	Failure = "Failure",
	Rejected = "Rejected",
	Cancelled = "Cancelled",
}

Types.ExecutionPolicy = {
	AuthoritativeSingleOwner = "AuthoritativeSingleOwner",
}

Types.ExecutionMode = {
	Immediate = "Immediate",
	Deferred = "Deferred",
	Scheduled = "Scheduled",
	Exclusive = "Exclusive",
	Transactional = "Transactional",
	Batch = "Batch",
}

Types.IdempotencyPolicy = {
	RequireIdempotencyKey = "RequireIdempotencyKey",
	OptionalIdempotencyKey = "OptionalIdempotencyKey",
}

Types.RetryPolicy = {
	NeverRetry = "NeverRetry",
	RetryOnce = "RetryOnce",
	BoundedRetry = "BoundedRetry",
}

Types.CommandReplayPolicy = {
	ReplaySafe = "ReplaySafe",
	ReplayUnsafe = "ReplayUnsafe",
	ReplayMetadataOnly = "ReplayMetadataOnly",
}

Types.FailureType = {
	SchemaFailure = "SchemaFailure",
	AuthorizationFailure = "AuthorizationFailure",
	AuthorityFailure = "AuthorityFailure",
	RoutingFailure = "RoutingFailure",
	HandlerFailure = "HandlerFailure",
	QueueFailure = "QueueFailure",
	CancellationFailure = "CancellationFailure",
	InternalRuntimeFailure = "InternalRuntimeFailure",
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
	ExecutionTimeoutFailure = "ExecutionTimeoutFailure",
	TransactionFailure = "TransactionFailure",
	RollbackFailure = "RollbackFailure",
	LockFailure = "LockFailure",
	LockTimeoutFailure = "LockTimeoutFailure",
	ReplayFailure = "ReplayFailure",
	InterruptedExecutionFailure = "InterruptedExecutionFailure",
	RetryLimitExceeded = "RetryLimitExceeded",
	CircularCommandFailure = "CircularCommandFailure",
	NestedCommandDepthExceeded = "NestedCommandDepthExceeded",
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
	MaxLocksPerCommand = 12,
	DefaultExecutionBudget = 20,
	MaxExecutionBudget = 240,
	MaxRetryAttempts = 3,
	MaxNestedDepth = 32,
	MaxBatches = 80,
	MaxTransactions = 80,
	MaxTimelineEventsPerCommand = 40,
	MaxObservabilityEvents = 240,
	MaxTraceGraphEdges = 480,
	MaxThroughputHistory = 120,
	MaxSessionCommands = 240,
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

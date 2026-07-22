--!strict

local Types = {}

Types.ProviderName = "runtimeQueryBus"

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
	Authorized = "Authorized",
	Queued = "Queued",
	Dispatched = "Dispatched",
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

Types.Consistency = {
	Strong = "Strong",
	Snapshot = "Snapshot",
	EventuallyConsistent = "EventuallyConsistent",
	Historical = "Historical",
}

Types.CachePolicy = {
	NoCache = "NoCache",
	ReadThrough = "ReadThrough",
	SnapshotCache = "SnapshotCache",
}

Types.CompatibilityPolicy = {
	Compatible = "Compatible",
	Versioned = "Versioned",
	Deprecated = "Deprecated",
}

Types.FailureType = {
	SchemaFailure = "SchemaFailure",
	AuthorizationFailure = "AuthorizationFailure",
	RoutingFailure = "RoutingFailure",
	HandlerFailure = "HandlerFailure",
	QueueFailure = "QueueFailure",
	ValidationFailure = "ValidationFailure",
	UnknownQueryType = "UnknownQueryType",
	UnknownRequester = "UnknownRequester",
	RequesterNotAuthorized = "RequesterNotAuthorized",
	UnknownHandler = "UnknownHandler",
	AmbiguousOwner = "AmbiguousOwner",
	InvalidPayload = "InvalidPayload",
	InvalidPriority = "InvalidPriority",
	InvalidConsistency = "InvalidConsistency",
	QueueFull = "QueueFull",
	DuplicateQueryId = "DuplicateQueryId",
	DuplicateQueryType = "DuplicateQueryType",
	DuplicateHandler = "DuplicateHandler",
	NoHandler = "NoHandler",
	CancellationRejected = "CancellationRejected",
	ExecutionFailure = "ExecutionFailure",
	MutationAttemptFailure = "MutationAttemptFailure",
	ShutdownRejected = "ShutdownRejected",
}

Types.Limits = {
	MaxQueryTypes = 240,
	MaxRequesters = 160,
	MaxHandlers = 240,
	MaxQueueDepth = 240,
	MaxEvidence = 360,
	MaxExecutionHistory = 240,
	MaxPayloadDepth = 8,
	MaxPayloadNodes = 180,
	MaxStringLength = 2048,
	MaxBatchSize = 40,
	MaxTimelineEvents = 240,
	MaxInspectionHistory = 120,
	MaxProjectionCount = 120,
	MaxSnapshotCount = 120,
	MaxCacheEntries = 120,
}

Types.CoreQueryTypes = {
	Test = "core.query.test",
}

return Types

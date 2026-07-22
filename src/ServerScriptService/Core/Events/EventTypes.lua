--!strict

local Types = {}

Types.ProviderName = "runtimeEventBus"

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

Types.DeliveryPolicy = {
	AtMostOnce = "AtMostOnce",
	BestEffort = "BestEffort",
}

Types.ReplayPolicy = {
	ReplaySafe = "ReplaySafe",
	ReplayUnsafe = "ReplayUnsafe",
	ReplayMetadataOnly = "ReplayMetadataOnly",
}

Types.NoSubscriberPolicy = {
	AllowNoSubscribers = "AllowNoSubscribers",
	RequireSubscriber = "RequireSubscriber",
}

Types.FailurePolicy = {
	ContinueAfterSubscriberFailure = "ContinueAfterSubscriberFailure",
	FailFast = "FailFast",
}

Types.Status = {
	Created = "Created",
	Validated = "Validated",
	Queued = "Queued",
	Routing = "Routing",
	Dispatching = "Dispatching",
	Delivered = "Delivered",
	Cancelled = "Cancelled",
	Rejected = "Rejected",
	Dropped = "Dropped",
	Failed = "Failed",
}

Types.FailureType = {
	ValidationFailure = "ValidationFailure",
	UnknownEventType = "UnknownEventType",
	UnknownPublisher = "UnknownPublisher",
	PublisherNotAuthorized = "PublisherNotAuthorized",
	InvalidPayload = "InvalidPayload",
	InvalidPriority = "InvalidPriority",
	InvalidReplayPolicy = "InvalidReplayPolicy",
	QueueFull = "QueueFull",
	DuplicateEventId = "DuplicateEventId",
	RoutingFailure = "RoutingFailure",
	NoSubscribers = "NoSubscribers",
	SubscriberFailure = "SubscriberFailure",
	CancellationRejected = "CancellationRejected",
	RecursivePublishRejected = "RecursivePublishRejected",
	DispatchFailure = "DispatchFailure",
	ShutdownRejected = "ShutdownRejected",
}

Types.Limits = {
	MaxEventTypes = 240,
	MaxPublishers = 160,
	MaxSubscribers = 240,
	MaxQueueDepth = 320,
	MaxDispatchHistory = 240,
	MaxEvidence = 360,
	MaxPayloadDepth = 8,
	MaxPayloadNodes = 180,
	MaxStringLength = 2048,
	MaxMetadataKeys = 32,
	MaxDispatchDepth = 8,
	MaxCausationDepth = 12,
	MaxBatchSize = 40,
}

Types.CoreEventTypes = {
	Test = "core.event.test",
	RuntimeStarted = "core.runtime.started",
	RuntimeStopped = "core.runtime.stopped",
	RuntimeFailureRecorded = "core.runtime.failure_recorded",
}

Types.SignalNames = {
	EventSubmitted = "runtimeEventBus.eventSubmitted",
	EventValidated = "runtimeEventBus.eventValidated",
	EventQueued = "runtimeEventBus.eventQueued",
	EventRouting = "runtimeEventBus.eventRouting",
	EventDispatching = "runtimeEventBus.eventDispatching",
	EventDelivered = "runtimeEventBus.eventDelivered",
	EventRejected = "runtimeEventBus.eventRejected",
	EventCancelled = "runtimeEventBus.eventCancelled",
	EventDropped = "runtimeEventBus.eventDropped",
	EventFailed = "runtimeEventBus.eventFailed",
	SubscriberFailed = "runtimeEventBus.subscriberFailed",
}

return Types

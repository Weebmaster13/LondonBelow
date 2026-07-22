--!strict

local Types = {}

Types.ProviderName = "runtimeMessagingIntegration"

Types.LifecycleState = {
	Created = "Created",
	Registered = "Registered",
	Validated = "Validated",
	Initialized = "Initialized",
	Ready = "Ready",
	Running = "Running",
	Suspended = "Suspended",
	Shutdown = "Shutdown",
}

Types.AuthorityLevel = {
	Core = "Core",
	Runtime = "Runtime",
	Gameplay = "Gameplay",
	Presentation = "Presentation",
	ReadOnly = "ReadOnly",
}

Types.SubscriptionDeliveryMode = {
	Ordered = "Ordered",
	Deferred = "Deferred",
	Once = "Once",
}

Types.HealthStatus = {
	Healthy = "Healthy",
	Warning = "Warning",
	Blocked = "Blocked",
	Shutdown = "Shutdown",
}

Types.FailureType = {
	ValidationFailure = "ValidationFailure",
	DuplicateConsumer = "DuplicateConsumer",
	DuplicateSubscription = "DuplicateSubscription",
	MissingDependency = "MissingDependency",
	DependencyCycle = "DependencyCycle",
	InvalidLifecycleTransition = "InvalidLifecycleTransition",
	UnknownConsumer = "UnknownConsumer",
	UnknownInterface = "UnknownInterface",
	UnsupportedAuthority = "UnsupportedAuthority",
	UnsupportedDeliveryMode = "UnsupportedDeliveryMode",
	UnsafePayload = "UnsafePayload",
}

Types.Limits = {
	MaxConsumers = 160,
	MaxDependenciesPerConsumer = 32,
	MaxSubscriptions = 320,
	MaxInterfacesPerConsumer = 64,
	MaxEvidence = 360,
	MaxFailures = 120,
	MaxStringLength = 2048,
	MaxPayloadDepth = 8,
	MaxPayloadNodes = 220,
}

Types.CoreConsumerId = Types.ProviderName

return Types

--!strict

local Types = {}

Types.ProviderName = "runtimeCapabilityFramework"

Types.Category = {
	Core = "Core",
	Gameplay = "Gameplay",
	AI = "AI",
	Narrative = "Narrative",
	Audio = "Audio",
	Presentation = "Presentation",
	UI = "UI",
	Save = "Save",
	World = "World",
	Networking = "Networking",
	Tooling = "Tooling",
}

Types.Authority = {
	Core = "Core",
	Server = "Server",
	ReadOnly = "ReadOnly",
	Presentation = "Presentation",
	Tooling = "Tooling",
}

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

Types.Health = {
	Healthy = "Healthy",
	Degraded = "Degraded",
	Unavailable = "Unavailable",
	Unknown = "Unknown",
}

Types.Readiness = {
	Ready = "Ready",
	Blocked = "Blocked",
	NotReady = "NotReady",
}

Types.Availability = {
	Available = "Available",
	Unavailable = "Unavailable",
	Suspended = "Suspended",
}

Types.FailureType = {
	ValidationFailure = "ValidationFailure",
	DuplicateCapability = "DuplicateCapability",
	UnknownCapability = "UnknownCapability",
	UnknownDependency = "UnknownDependency",
	MissingInterface = "MissingInterface",
	InvalidLifecycleTransition = "InvalidLifecycleTransition",
	InvalidCategory = "InvalidCategory",
	InvalidAuthority = "InvalidAuthority",
	DependencyCycle = "DependencyCycle",
	IncompatibleVersion = "IncompatibleVersion",
	UnsafePayload = "UnsafePayload",
	RuntimeShutdown = "RuntimeShutdown",
	LimitExceeded = "LimitExceeded",
}

Types.Limits = {
	MaxCapabilities = 180,
	MaxInterfacesPerCapability = 40,
	MaxDependenciesPerCapability = 40,
	MaxDiagnostics = 420,
	MaxSnapshots = 80,
	MaxEvidence = 520,
	MaxStringLength = 2048,
	MaxPayloadDepth = 8,
	MaxPayloadNodes = 260,
}

return Types

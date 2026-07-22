--!strict

local Types = {}

Types.ProviderName = "runtimeDomainCapabilityFoundation"

Types.Domain = {
	Dialogue = "Dialogue",
	Inventory = "Inventory",
	Objectives = "Objectives",
	LivingCognition = "LivingCognition",
	Presentation = "Presentation",
	Weather = "Weather",
	Audio = "Audio",
	Save = "Save",
	AIPerception = "AIPerception",
	NpcRuntime = "NpcRuntime",
	WorldSimulation = "WorldSimulation",
}

Types.Authority = {
	ReadOnly = "ReadOnly",
	Server = "Server",
	Presentation = "Presentation",
	Core = "Core",
}

Types.WorkflowParticipation = {
	None = "None",
	Observer = "Observer",
	Participant = "Participant",
	Coordinator = "Coordinator",
}

Types.FailureType = {
	ValidationFailure = "ValidationFailure",
	DuplicateDomainCapability = "DuplicateDomainCapability",
	DuplicateDomain = "DuplicateDomain",
	UnknownDomainCapability = "UnknownDomainCapability",
	UnsupportedDomain = "UnsupportedDomain",
	UnsupportedAuthority = "UnsupportedAuthority",
	UnsupportedWorkflowParticipation = "UnsupportedWorkflowParticipation",
	InvalidInterface = "InvalidInterface",
	InvalidDependency = "InvalidDependency",
	UnsafePayload = "UnsafePayload",
	CapabilityFrameworkRejected = "CapabilityFrameworkRejected",
	RuntimeShutdown = "RuntimeShutdown",
	LimitExceeded = "LimitExceeded",
}

Types.Limits = {
	MaxDomainCapabilities = 160,
	MaxInterfacesPerDomain = 40,
	MaxDependenciesPerDomain = 40,
	MaxServiceMethodsPerInterface = 40,
	MaxEvidence = 520,
	MaxStringLength = 2048,
	MaxPayloadDepth = 8,
	MaxPayloadNodes = 260,
}

return Types

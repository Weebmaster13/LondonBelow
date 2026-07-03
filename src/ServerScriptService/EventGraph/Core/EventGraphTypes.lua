--!strict
-- Shared constants and runtime limits for Phase 40 Event Graph Foundation.

local Types = {}

Types.Mode = "ServerAuthoritativeEventGraphSchemaRuntime"

Types.SchemaType = {
	EventNodeSchema = "EventNodeSchema",
	EventChannelSchema = "EventChannelSchema",
	EventEdgeSchema = "EventEdgeSchema",
	EventSourceSchema = "EventSourceSchema",
	EventSinkSchema = "EventSinkSchema",
	EventSubscriptionSchema = "EventSubscriptionSchema",
	EventPropagationSchema = "EventPropagationSchema",
	EventPrioritySchema = "EventPrioritySchema",
	EventFilterSchema = "EventFilterSchema",
	EventPayloadContractSchema = "EventPayloadContractSchema",
	EventOrderingSchema = "EventOrderingSchema",
	EventAuditSchema = "EventAuditSchema",
	SystemEventGraphSchema = "SystemEventGraphSchema",
}

Types.EventDomain = {
	Core = true,
	Runtime = true,
	Lifecycle = true,
	Scheduler = true,
	Observation = true,
	Director = true,
	Horror = true,
	AI = true,
	Monster = true,
	Gameplay = true,
	Physical = true,
	Presentation = true,
	Interaction = true,
	Puzzle = true,
	Inventory = true,
	World = true,
	Objective = true,
	Session = true,
	Persistence = true,
	DeveloperTools = true,
	Analytics = true,
	Accessibility = true,
	Performance = true,
	Security = true,
	Localization = true,
	ContentRegistry = true,
	RuntimeGraph = true,
	EventGraph = true,
	Chapter = true,
	System = true,
	Future = true,
}

Types.ChannelKind = {
	SystemChannel = true,
	RuntimeChannel = true,
	DiagnosticChannel = true,
	SnapshotChannel = true,
	ValidationChannel = true,
	GameplayChannel = true,
	PresentationChannel = true,
	PersistenceChannel = true,
	SecurityChannel = true,
	FutureChannel = true,
}

Types.EdgeKind = {
	Emits = true,
	Consumes = true,
	Observes = true,
	DependsOn = true,
	MustPrecede = true,
	MustFollow = true,
	Suppresses = true,
	Mirrors = true,
	Audits = true,
	FutureEdge = true,
}

Types.PropagationKind = {
	NoPropagation = true,
	DirectSchema = true,
	CascadingSchema = true,
	BoundedSchema = true,
	PrioritySchema = true,
	FuturePropagation = true,
}

Types.PriorityKind = {
	Critical = true,
	High = true,
	Normal = true,
	Low = true,
	Background = true,
	FutureOnly = true,
}

Types.FilterKind = {
	NoFilter = true,
	DomainFilter = true,
	ChannelFilter = true,
	SourceFilter = true,
	SinkFilter = true,
	PayloadShapeFilter = true,
	FutureFilter = true,
}

Types.OrderingKind = {
	Before = true,
	After = true,
	SamePhase = true,
	Independent = true,
	Deferred = true,
	FutureOnly = true,
}

Types.Limits = {
	MaxEventNodes = 700,
	MaxChannels = 500,
	MaxEdges = 1000,
	MaxSources = 700,
	MaxSinks = 700,
	MaxSubscriptions = 900,
	MaxPropagations = 600,
	MaxPriorities = 400,
	MaxFilters = 500,
	MaxPayloadContracts = 700,
	MaxOrderings = 900,
	MaxAudits = 500,
	MaxValidationFailures = 240,
	MaxSnapshotHistory = 80,
	MaxPayloadDepth = 9,
	MaxPayloadNodes = 460,
	MaxPayloadStringLength = 700,
	MaxTagsPerSchema = 32,
	MaxNodeChannels = 80,
	MaxNodeSources = 80,
	MaxNodeSinks = 80,
	MaxNodePayloadContracts = 80,
	MaxSubscriptionFilters = 80,
	MaxPropagationChannels = 80,
	MaxPropagationFilters = 80,
	MaxPayloadAllowedFields = 120,
	MaxPayloadRequiredFields = 120,
	MaxPayloadForbiddenFields = 120,
	MaxAuditFindings = 96,
}

return Types

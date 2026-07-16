--!strict

local Types = {}

Types.RuntimeName = "Chapter0Home"
Types.ProviderName = "chapter0Home"
Types.SnapshotProviderName = "chapter0Home"
Types.ChapterId = "chapter_0_home"
Types.RootFolderName = "Chapter0Home"

Types.PhaseStatus = {
	NotStarted = "NotStarted",
	Started = "Started",
	Completed = "Completed",
	Reset = "Reset",
}

Types.RoomKind = {
	Apartment = "Apartment",
	Hall = "Hall",
	Bedroom = "Bedroom",
}

Types.InteractionKind = {
	Note = "Note",
	Switch = "Switch",
	Collectible = "Collectible",
	Door = "Door",
}

Types.FeedbackKind = {
	Audio = "Audio",
	Visual = "Visual",
	Prompt = "Prompt",
	Haptics = "Haptics",
	ScreenEffect = "ScreenEffect",
}

Types.EnvironmentalReactionKind = {
	AttributeShift = "AttributeShift",
	PromptState = "PromptState",
	RoomPressure = "RoomPressure",
}

Types.EnvironmentalReactionTargetKind = {
	Interaction = "Interaction",
	Room = "Room",
	ChapterRoot = "ChapterRoot",
}

Types.EnvironmentalReactionAttributePrefix = "Atmosphere_"

Types.EnvironmentalReactionAttributeNames = {
	ReactionId = "AtmosphereReactionId",
	InteractionId = "AtmosphereInteractionId",
	Kind = "AtmosphereKind",
	TargetKind = "AtmosphereTargetKind",
	TargetId = "AtmosphereTargetId",
	Intensity = "AtmosphereIntensity",
	Order = "AtmosphereOrder",
}

Types.CanonicalEnvironmentalReactionIds = {
	"chapter0_home_note_room_attention",
	"chapter0_home_lamp_warmth_state",
	"chapter0_home_ribbon_hall_pressure",
	"chapter0_home_bedroom_door_resistance",
}

Types.InitialAtmosphericProgressionStageId = "chapter0_home_quiet_initial"

Types.CanonicalAtmosphericProgressionStageIds = {
	"chapter0_home_quiet_initial",
	"chapter0_home_note_acknowledged",
	"chapter0_home_lamp_unsteady_comfort",
	"chapter0_home_ribbon_quiet_escalation",
}

Types.CanonicalAtmosphericProgressionTransitionIds = {
	"chapter0_home_progression_note_acknowledged",
	"chapter0_home_progression_lamp_unsteady_comfort",
	"chapter0_home_progression_ribbon_quiet_escalation",
	"chapter0_home_progression_bedroom_door_resistance_modifier",
}

Types.AtmosphericProgressionPostureKeys = {
	"serverAuthoritative",
	"deterministicOrdering",
	"exactStageDefinitions",
	"exactTransitionDefinitions",
	"exactInitialStage",
	"exactReferenceBindings",
	"transitionSequenceValidated",
	"optionalModifierNonBlocking",
	"repeatedTransitionsIdempotent",
	"failedValidationNoMutation",
	"boundedHistory",
	"deterministicHistoryEviction",
	"perPlayerIsolated",
	"resetDeterministic",
	"shutdownOwnedCleanup",
	"existingFeedbackReused",
	"existingReactionsReused",
	"noNewRemotes",
	"noPersistence",
	"noAnalytics",
	"noTelemetry",
	"noMonsterAI",
	"noChapter1Content",
}

Types.CanonicalAtmosphericProgressionStageDefinitions = {
	{
		stageId = "chapter0_home_quiet_initial",
		order = 1,
		initial = true,
		intensity = 0.05,
		completionRelevant = false,
		metadata = {
			atmosphericState = "quietStable",
			narrativePressure = "none",
			presentationPosture = "minimal",
		},
	},
	{
		stageId = "chapter0_home_note_acknowledged",
		order = 2,
		initial = false,
		intensity = 0.25,
		completionRelevant = false,
		metadata = {
			atmosphericState = "absenceAcknowledged",
			narrativePressure = "mumNote",
			presentationPosture = "attentive",
		},
	},
	{
		stageId = "chapter0_home_lamp_unsteady_comfort",
		order = 3,
		initial = false,
		intensity = 0.38,
		completionRelevant = false,
		metadata = {
			atmosphericState = "warmButUnsteady",
			narrativePressure = "houseListening",
			presentationPosture = "restrainedWarmth",
		},
	},
	{
		stageId = "chapter0_home_ribbon_quiet_escalation",
		order = 4,
		initial = false,
		intensity = 0.52,
		completionRelevant = true,
		metadata = {
			atmosphericState = "quietEscalation",
			narrativePressure = "marmaladeAbsent",
			presentationPosture = "uneasy",
		},
	},
}

Types.CanonicalAtmosphericProgressionTransitionDefinitions = {
	{
		transitionId = "chapter0_home_progression_note_acknowledged",
		interactionId = "chapter0_home_note",
		fromStageId = "chapter0_home_quiet_initial",
		toStageId = "chapter0_home_note_acknowledged",
		order = 1,
		requiredInteractionIds = { "chapter0_home_note" },
		feedbackId = "chapter0_home_note_context",
		reactionId = "chapter0_home_note_room_attention",
		optionalModifier = false,
		completionRelevant = false,
		intensity = 0.25,
		metadata = {
			progressionBeat = "noteAcknowledged",
			stageIntent = "emotionalContext",
			resetState = "deterministic",
		},
	},
	{
		transitionId = "chapter0_home_progression_lamp_unsteady_comfort",
		interactionId = "chapter0_home_lamp",
		fromStageId = "chapter0_home_note_acknowledged",
		toStageId = "chapter0_home_lamp_unsteady_comfort",
		order = 2,
		requiredInteractionIds = { "chapter0_home_note", "chapter0_home_lamp" },
		feedbackId = "chapter0_home_lamp_response",
		reactionId = "chapter0_home_lamp_warmth_state",
		optionalModifier = false,
		completionRelevant = false,
		intensity = 0.38,
		metadata = {
			progressionBeat = "lampComfortUnsteady",
			stageIntent = "restrainedWarmth",
			resetState = "deterministic",
		},
	},
	{
		transitionId = "chapter0_home_progression_ribbon_quiet_escalation",
		interactionId = "chapter0_home_marmalade_ribbon",
		fromStageId = "chapter0_home_lamp_unsteady_comfort",
		toStageId = "chapter0_home_ribbon_quiet_escalation",
		order = 3,
		requiredInteractionIds = {
			"chapter0_home_note",
			"chapter0_home_lamp",
			"chapter0_home_marmalade_ribbon",
		},
		feedbackId = "chapter0_home_ribbon_escalation",
		reactionId = "chapter0_home_ribbon_hall_pressure",
		optionalModifier = false,
		completionRelevant = true,
		intensity = 0.52,
		metadata = {
			progressionBeat = "ribbonEscalation",
			stageIntent = "quietEscalation",
			resetState = "deterministic",
		},
	},
	{
		transitionId = "chapter0_home_progression_bedroom_door_resistance_modifier",
		interactionId = "chapter0_home_bedroom_door",
		fromStageId = "chapter0_home_ribbon_quiet_escalation",
		toStageId = nil,
		order = 4,
		requiredInteractionIds = { "chapter0_home_bedroom_door" },
		feedbackId = "chapter0_home_bedroom_door_warning",
		reactionId = "chapter0_home_bedroom_door_resistance",
		optionalModifier = true,
		completionRelevant = false,
		intensity = 0.18,
		metadata = {
			progressionBeat = "bedroomDoorResistance",
			stageIntent = "optionalUnease",
			resetState = "deterministic",
		},
	},
}

Types.OptionalAtmosphericProgressionModifierTransitionId =
	"chapter0_home_progression_bedroom_door_resistance_modifier"

Types.RequiredInteractions = {
	"chapter0_home_note",
	"chapter0_home_lamp",
	"chapter0_home_marmalade_ribbon",
}

Types.Limits = {
	MaxRooms = 4,
	MaxInteractables = 8,
	MaxRoomConnections = 4,
	MaxEvents = 64,
	MaxValidationFailures = 32,
	MaxPlayerStates = 32,
	MaxFeedbackDefinitions = 8,
	MaxFeedbackHistoryPerPlayer = 8,
	MaxFeedbackMetadataKeys = 8,
	MaxFeedbackInstructionIdLength = 80,
	MaxEnvironmentalReactionDefinitions = 8,
	MaxEnvironmentalReactionHistoryPerPlayer = 8,
	MaxEnvironmentalReactionMetadataKeys = 8,
	MaxAtmosphericProgressionStages = 6,
	MaxAtmosphericProgressionTransitions = 8,
	MaxAtmosphericProgressionMetadataKeys = 8,
	MaxAtmosphericProgressionHistoryPerPlayer = 8,
	MaxAtmosphericProgressionOptionalModifiers = 4,
	MaxAtmosphericProgressionTransitionRequirements = 4,
	MaxMetadataDepth = 4,
	MaxRoomDimension = 64,
	MaxInteractionDimension = 12,
	MaxCoordinateMagnitude = 512,
}

export type RoomDefinition = {
	roomId: string,
	displayName: string,
	kind: string,
	position: Vector3,
	size: Vector3,
	connections: { string },
}

export type InteractionDefinition = {
	interactionId: string,
	roomId: string,
	kind: string,
	prompt: string,
	position: Vector3,
	size: Vector3,
	requiredForCompletion: boolean,
	metadata: { [string]: any },
}

export type AtmosphericFeedbackDefinition = {
	feedbackId: string,
	interactionId: string,
	kind: string,
	instructionId: string,
	intensity: number,
	duration: number?,
	order: number,
	metadata: { [string]: any },
}

export type EnvironmentalReactionDefinition = {
	reactionId: string,
	interactionId: string,
	kind: string,
	targetKind: string,
	targetId: string,
	order: number,
	intensity: number,
	metadata: { [string]: any },
}

export type AtmosphericProgressionStageDefinition = {
	stageId: string,
	order: number,
	initial: boolean,
	intensity: number,
	completionRelevant: boolean,
	metadata: { [string]: any },
}

export type AtmosphericProgressionTransitionDefinition = {
	transitionId: string,
	interactionId: string,
	fromStageId: string,
	toStageId: string?,
	order: number,
	requiredInteractionIds: { string },
	feedbackId: string,
	reactionId: string,
	optionalModifier: boolean,
	completionRelevant: boolean,
	intensity: number,
	metadata: { [string]: any },
}

export type ChapterDefinition = {
	chapterId: string,
	displayName: string,
	spawnPosition: Vector3,
	rooms: { RoomDefinition },
	interactions: { InteractionDefinition },
	completionInteractionIds: { string },
	atmosphericFeedback: { AtmosphericFeedbackDefinition },
	environmentalReactions: { EnvironmentalReactionDefinition },
	atmosphericProgressionStages: { AtmosphericProgressionStageDefinition },
	atmosphericProgressionTransitions: { AtmosphericProgressionTransitionDefinition },
}

export type PlayerProgress = {
	userId: number,
	status: string,
	interactions: { [string]: boolean },
	feedbackHistory: { any },
	reactionHistory: { any },
	progressionStageId: string,
	progressionTransitions: { [string]: boolean },
	progressionHistory: { any },
	optionalAtmosphericModifiers: { any },
	completedAt: number?,
}

return Types

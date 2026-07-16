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

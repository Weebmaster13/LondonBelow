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

export type ChapterDefinition = {
	chapterId: string,
	displayName: string,
	spawnPosition: Vector3,
	rooms: { RoomDefinition },
	interactions: { InteractionDefinition },
	completionInteractionIds: { string },
	atmosphericFeedback: { AtmosphericFeedbackDefinition },
	environmentalReactions: { EnvironmentalReactionDefinition },
}

export type PlayerProgress = {
	userId: number,
	status: string,
	interactions: { [string]: boolean },
	feedbackHistory: { any },
	reactionHistory: { any },
	completedAt: number?,
}

return Types

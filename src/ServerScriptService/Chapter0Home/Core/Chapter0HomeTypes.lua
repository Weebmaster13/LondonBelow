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

Types.RequiredInteractions = {
	"chapter0_home_note",
	"chapter0_home_lamp",
	"chapter0_home_marmalade_ribbon",
}

Types.Limits = {
	MaxRooms = 4,
	MaxInteractables = 8,
	MaxEvents = 64,
	MaxPlayerStates = 32,
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

export type ChapterDefinition = {
	chapterId: string,
	displayName: string,
	spawnPosition: Vector3,
	rooms: { RoomDefinition },
	interactions: { InteractionDefinition },
	completionInteractionIds: { string },
}

export type PlayerProgress = {
	userId: number,
	status: string,
	interactions: { [string]: boolean },
	completedAt: number?,
}

return Types

--!strict
--[[
	Stable type names for the London Engine Environment Director.

	The Environment Director approves world reactions. It does not perform final
	world mutation, render effects, play sounds, or author chapter content.
]]

local EnvironmentDirectorTypes = {}

export type ReactionCategory =
	"FogPressure"
	| "RainPressure"
	| "WindPressure"
	| "DoorReaction"
	| "PropShift"
	| "RoomPressure"
	| "StreetPressure"
	| "BuildingAttention"
	| "WindowPresence"
	| "CarriageAtmosphere"
	| "SilenceSupport"
	| "ChaseSupport"
	| "ReleaseSupport"
	| "PuzzlePressure"
	| "SafeRoomProtection"

export type ReactionState = "Idle" | "Building" | "Active" | "CoolingDown" | "Suppressed" | "Failed"
export type PressureState = "Calm" | "Watchful" | "Uneasy" | "Oppressive" | "Hostile" | "Release"
export type ZoneKind =
	"Street"
	| "Alley"
	| "Lobby"
	| "Carriage"
	| "Foyer"
	| "Hallway"
	| "PuzzleRoom"
	| "SafeRoom"
	| "ChaseRoute"
	| "Exterior"
	| "Interior"
	| "Unknown"

export type ExecutionKind =
	"ApplyFogPressure"
	| "ApplyRainPressure"
	| "ApplyWindPressure"
	| "RequestDoorReaction"
	| "RequestPropShift"
	| "RequestRoomPressure"
	| "RequestBuildingAttention"
	| "RequestCarriageAtmosphere"

export type ReactionDefinition = {
	id: string,
	category: ReactionCategory,
	displayName: string,
	intensity: number,
	allowedPressureStates: { PressureState },
	cooldownSeconds: number,
	zoneCooldownSeconds: number,
	maxRepeats: number,
	supportsSolo: boolean,
	supportsGroup: boolean,
	requiresApprovalFrom: { string },
	suppressionRules: { string },
	tags: { string },
	executionKind: ExecutionKind,
	safeForPuzzle: boolean,
	safeForChase: boolean,
	safeForRelease: boolean,
	description: string,
}

export type SelectionContext = {
	playerUserId: number?,
	partySize: number,
	zoneId: string,
	zoneKind: ZoneKind,
	pressureState: PressureState,
	requestKind: string?,
	preferredCategory: ReactionCategory?,
	metadata: { [string]: any },
	tags: { string },
	now: number,
}

export type ReactionDecision = {
	requestId: string?,
	reactionId: string?,
	category: ReactionCategory?,
	status: "Selected" | "Rejected" | "Deferred" | "Silence",
	reason: string,
	blocked: { string },
	executionKind: ExecutionKind?,
	createdAt: number,
	context: SelectionContext,
}

EnvironmentDirectorTypes.PressureScore = {
	Calm = 0,
	Watchful = 1,
	Uneasy = 2,
	Oppressive = 3,
	Hostile = 4,
	Release = -1,
}

EnvironmentDirectorTypes.ValidPressureStates = {
	Calm = true,
	Watchful = true,
	Uneasy = true,
	Oppressive = true,
	Hostile = true,
	Release = true,
}

EnvironmentDirectorTypes.ValidReactionCategories = {
	FogPressure = true,
	RainPressure = true,
	WindPressure = true,
	DoorReaction = true,
	PropShift = true,
	RoomPressure = true,
	StreetPressure = true,
	BuildingAttention = true,
	WindowPresence = true,
	CarriageAtmosphere = true,
	SilenceSupport = true,
	ChaseSupport = true,
	ReleaseSupport = true,
	PuzzlePressure = true,
	SafeRoomProtection = true,
}

EnvironmentDirectorTypes.ValidZoneKinds = {
	Street = true,
	Alley = true,
	Lobby = true,
	Carriage = true,
	Foyer = true,
	Hallway = true,
	PuzzleRoom = true,
	SafeRoom = true,
	ChaseRoute = true,
	Exterior = true,
	Interior = true,
	Unknown = true,
}

EnvironmentDirectorTypes.ValidExecutionKinds = {
	ApplyFogPressure = true,
	ApplyRainPressure = true,
	ApplyWindPressure = true,
	RequestDoorReaction = true,
	RequestPropShift = true,
	RequestRoomPressure = true,
	RequestBuildingAttention = true,
	RequestCarriageAtmosphere = true,
}

return EnvironmentDirectorTypes

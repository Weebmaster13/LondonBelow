--!strict
--[[
	World Intelligence type contracts for London Engine.

	This module defines the vocabulary future systems use to describe places.
	It does not load maps, create rooms, mutate Workspace, spawn monsters, play
	sounds, or decide horror pacing. Chapter content should instantiate these
	contracts through registries and observations instead of hard-coding spatial
	meaning inside gameplay scripts.
]]

local WorldTypes = {}

export type WorldLayer =
	"District"
	| "Street"
	| "Building"
	| "Floor"
	| "Wing"
	| "Room"
	| "MicroZone"

export type ZoneKind =
	"District"
	| "Street"
	| "Building"
	| "Floor"
	| "Wing"
	| "Room"
	| "MicroZone"
	| "SafeRoom"
	| "PuzzleRoom"
	| "ChaseRoute"
	| "Exterior"
	| "Interior"
	| "Transition"
	| "Unknown"

export type AtmosphereProfileId =
	"VictorianFog"
	| "DampInterior"
	| "Candlelit"
	| "GaslitStreet"
	| "AbandonedInstitution"
	| "SafeSilence"
	| "PuzzleFocus"
	| "ChasePressure"
	| "Unknown"

export type RoomPersonalityId =
	"Neutral"
	| "Watching"
	| "Hostile"
	| "Protective"
	| "Mourning"
	| "Deceptive"
	| "PuzzleFocused"
	| "Transit"
	| "Unknown"

export type AffordanceId =
	"AllowWhispers"
	| "AllowHeartbeat"
	| "AllowBreathing"
	| "AllowLanternFlicker"
	| "AllowFog"
	| "AllowRainMuffle"
	| "AllowDoorReaction"
	| "AllowPropShift"
	| "AllowLightDimming"
	| "AllowSilenceDrop"
	| "AllowMonsterPresence"
	| "AllowMonsterReveal"
	| "AllowCrawlerPresence"
	| "AllowChase"
	| "ProtectPuzzleFocus"
	| "ProtectSafeRoom"
	| "AllowCooperativePressure"

export type LightingPolicy = {
	minBrightness: number,
	maxBrightness: number,
	allowsBlackout: boolean,
	allowsFlicker: boolean,
	allowsDirectionalMislead: boolean,
}

export type AudioPolicy = {
	allowsWhispers: boolean,
	allowsFakeSounds: boolean,
	allowsHeartbeat: boolean,
	allowsBreathing: boolean,
	allowsSilenceDrop: boolean,
	allowedSoundTags: { string },
}

export type MonsterPolicy = {
	allowsMainMonsterPresence: boolean,
	allowsMainMonsterReveal: boolean,
	allowsCrawlerPresence: boolean,
	allowsChaseStart: boolean,
	allowsChaseContinuation: boolean,
	requiresDirectorApproval: boolean,
}

export type PuzzleProtectionPolicy = {
	protectsActivePuzzle: boolean,
	allowsSubtlePressure: boolean,
	allowsMajorInterruptions: boolean,
	reason: string,
}

export type AtmosphereProfile = {
	id: AtmosphereProfileId,
	displayName: string,
	intensityBias: number,
	fogAllowed: boolean,
	rainMuffleAllowed: boolean,
	lightingPolicy: LightingPolicy,
	audioPolicy: AudioPolicy,
	tags: { string },
	description: string,
}

export type RoomPersonalityProfile = {
	id: RoomPersonalityId,
	displayName: string,
	tensionBias: number,
	repetitionTolerance: number,
	preferredAffordances: { AffordanceId },
	suppressedAffordances: { AffordanceId },
	tags: { string },
	description: string,
}

export type WorldZoneProfile = {
	id: string,
	kind: ZoneKind,
	layer: WorldLayer?,
	displayName: string,
	parentId: string?,
	atmosphereProfileId: AtmosphereProfileId,
	roomPersonalityId: RoomPersonalityId,
	affordances: { AffordanceId },
	lightingPolicy: LightingPolicy,
	audioPolicy: AudioPolicy,
	monsterPolicy: MonsterPolicy,
	puzzleProtection: PuzzleProtectionPolicy,
	isSafeRoom: boolean,
	isPuzzleRoom: boolean,
	isChaseRoute: boolean,
	isExterior: boolean,
	isInterior: boolean,
	tags: { string },
	notes: string,
}

export type WorldContext = {
	zoneId: string,
	zoneKind: ZoneKind,
	parentId: string?,
	atmosphereProfileId: AtmosphereProfileId,
	roomPersonalityId: RoomPersonalityId,
	affordances: { AffordanceId },
	lightingPolicy: LightingPolicy,
	audioPolicy: AudioPolicy,
	monsterPolicy: MonsterPolicy,
	puzzleProtection: PuzzleProtectionPolicy,
	isKnown: boolean,
	tags: { string },
}

WorldTypes.ValidZoneKinds = {
	District = true,
	Street = true,
	Building = true,
	Floor = true,
	Wing = true,
	Room = true,
	MicroZone = true,
	SafeRoom = true,
	PuzzleRoom = true,
	ChaseRoute = true,
	Exterior = true,
	Interior = true,
	Transition = true,
	Unknown = true,
}

WorldTypes.ValidAtmosphereProfiles = {
	VictorianFog = true,
	DampInterior = true,
	Candlelit = true,
	GaslitStreet = true,
	AbandonedInstitution = true,
	SafeSilence = true,
	PuzzleFocus = true,
	ChasePressure = true,
	Unknown = true,
}

WorldTypes.ValidRoomPersonalities = {
	Neutral = true,
	Watching = true,
	Hostile = true,
	Protective = true,
	Mourning = true,
	Deceptive = true,
	PuzzleFocused = true,
	Transit = true,
	Unknown = true,
}

WorldTypes.ValidAffordances = {
	AllowWhispers = true,
	AllowHeartbeat = true,
	AllowBreathing = true,
	AllowLanternFlicker = true,
	AllowFog = true,
	AllowRainMuffle = true,
	AllowDoorReaction = true,
	AllowPropShift = true,
	AllowLightDimming = true,
	AllowSilenceDrop = true,
	AllowMonsterPresence = true,
	AllowMonsterReveal = true,
	AllowCrawlerPresence = true,
	AllowChase = true,
	ProtectPuzzleFocus = true,
	ProtectSafeRoom = true,
	AllowCooperativePressure = true,
}

return WorldTypes

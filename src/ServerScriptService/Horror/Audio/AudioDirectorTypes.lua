--!strict
--[[
	Stable contracts for the London Engine Audio Director.

	The Audio Director approves future sound pressure. It does not play sound,
	create Sound instances, use final assets, create client remotes, or own truth.
]]

local AudioDirectorTypes = {}

export type AudioPressureState = "Calm" | "Watchful" | "Uneasy" | "Oppressive" | "Release"

export type AudioRequestKind =
	"Whisper"
	| "FakeFootstep"
	| "DistantKnock"
	| "BreathingPressure"
	| "HeartbeatPressure"
	| "SilenceDrop"
	| "RainMuffle"
	| "RoomAmbience"
	| "SafeRoomProtection"
	| "PuzzleRoomProtection"

export type AudioDecisionStatus = "Approved" | "Rejected" | "Deferred"

export type AudioRequestDefinition = {
	id: string,
	requestKind: AudioRequestKind,
	displayName: string,
	intensity: number,
	requiresKnownZone: boolean,
	majorPressure: boolean,
	requiresWhisperPolicy: boolean,
	requiresFakeSoundPolicy: boolean,
	requiresHeartbeatPolicy: boolean,
	requiresBreathingPolicy: boolean,
	requiresSilencePolicy: boolean,
	requiresRainMufflePolicy: boolean,
	supportsSafeRoom: boolean,
	supportsPuzzleRoom: boolean,
	cooldownSeconds: number,
	tags: { string },
	description: string,
}

export type AudioContext = {
	playerUserId: number?,
	partySize: number,
	zoneId: string,
	zoneKind: string,
	isKnownZone: boolean,
	pressureState: AudioPressureState,
	requestKind: AudioRequestKind?,
	metadata: { [string]: any },
	tags: { string },
	worldContext: any,
	now: number,
}

export type AudioDecision = {
	requestId: string?,
	definitionId: string?,
	requestKind: AudioRequestKind?,
	status: AudioDecisionStatus,
	reason: string,
	blocked: { string },
	intensity: number,
	createdAt: number,
	context: AudioContext,
}

AudioDirectorTypes.ValidPressureStates = {
	Calm = true,
	Watchful = true,
	Uneasy = true,
	Oppressive = true,
	Release = true,
}

AudioDirectorTypes.ValidRequestKinds = {
	Whisper = true,
	FakeFootstep = true,
	DistantKnock = true,
	BreathingPressure = true,
	HeartbeatPressure = true,
	SilenceDrop = true,
	RainMuffle = true,
	RoomAmbience = true,
	SafeRoomProtection = true,
	PuzzleRoomProtection = true,
}

return AudioDirectorTypes

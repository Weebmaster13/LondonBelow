--!strict
--[[
	Stable contracts for the London Engine Lighting Director.

	The Lighting Director approves future visibility pressure. It does not change
	Roblox Lighting, mutate Workspace, create client effects, or own scare
	timing. It interprets World Intelligence policy and returns approval reasons.
]]

local LightingDirectorTypes = {}

export type LightingPressureState = "Calm" | "Watchful" | "Uneasy" | "Oppressive" | "Release"

export type LightingRequestKind =
	"Dim"
	| "Flicker"
	| "ShadowPressure"
	| "VisibilityPressure"
	| "SafeRoomProtection"
	| "PuzzleRoomProtection"
	| "ChaseSupport"
	| "ReleaseLighting"

export type LightingDecisionStatus = "Approved" | "Rejected" | "Deferred"

export type LightingRequestDefinition = {
	id: string,
	requestKind: LightingRequestKind,
	displayName: string,
	intensity: number,
	requiresKnownZone: boolean,
	requiresFlickerPolicy: boolean,
	requiresBlackoutPolicy: boolean,
	majorPressure: boolean,
	supportsSafeRoom: boolean,
	supportsPuzzleRoom: boolean,
	supportsChase: boolean,
	cooldownSeconds: number,
	tags: { string },
	description: string,
}

export type LightingContext = {
	playerUserId: number?,
	partySize: number,
	zoneId: string,
	zoneKind: string,
	isKnownZone: boolean,
	pressureState: LightingPressureState,
	requestKind: LightingRequestKind?,
	metadata: { [string]: any },
	tags: { string },
	worldContext: any,
	now: number,
}

export type LightingDecision = {
	requestId: string?,
	definitionId: string?,
	requestKind: LightingRequestKind?,
	status: LightingDecisionStatus,
	reason: string,
	blocked: { string },
	intensity: number,
	cooldownSeconds: number,
	createdAt: number,
	context: LightingContext,
}

LightingDirectorTypes.ValidPressureStates = {
	Calm = true,
	Watchful = true,
	Uneasy = true,
	Oppressive = true,
	Release = true,
}

LightingDirectorTypes.ValidRequestKinds = {
	Dim = true,
	Flicker = true,
	ShadowPressure = true,
	VisibilityPressure = true,
	SafeRoomProtection = true,
	PuzzleRoomProtection = true,
	ChaseSupport = true,
	ReleaseLighting = true,
}

return LightingDirectorTypes

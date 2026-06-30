--!strict
-- Type definitions for the cinematic lobby portal runtime.

local PortalTypes = {}

export type PortalKind = "VictorianCarriage" | "FogGate" | "ChapterDoor"

export type PortalState =
	"Idle"
	| "WaitingForParty"
	| "Boarding"
	| "ReadyToLaunch"
	| "Countdown"
	| "Transitioning"
	| "Launching"
	| "Failed"
	| "Cooldown"

export type PortalDefinition = {
	id: string,
	displayName: string,
	portalType: PortalKind,
	chapterId: string,
	enabled: boolean,
	maxPlayers: number,
	countdownSeconds: number,
	cooldownSeconds: number,
	cinematicSequence: { string },
}

export type PortalRuntime = {
	id: string,
	definition: PortalDefinition,
	state: PortalState,
	occupants: { [number]: number },
	leaderUserId: number?,
	partyId: string?,
	countdownRemaining: number,
	cooldownUntil: number,
	lastFailure: string?,
	stateEnteredAt: number,
	launchToken: number,
	updatedAt: number,
}

export type PortalResult = {
	ok: boolean,
	code: string,
	message: string,
	state: any?,
	data: any?,
}

PortalTypes.ResultCode = {
	Ok = "OK",
	InvalidRequest = "INVALID_REQUEST",
	PortalNotFound = "PORTAL_NOT_FOUND",
	PortalDisabled = "PORTAL_DISABLED",
	PortalFull = "PORTAL_FULL",
	NotInPortal = "NOT_IN_PORTAL",
	NotInParty = "NOT_IN_PARTY",
	NotLeader = "NOT_LEADER",
	PartyMismatch = "PARTY_MISMATCH",
	PartyNotReady = "PARTY_NOT_READY",
	PartyNotPresent = "PARTY_NOT_PRESENT",
	InvalidChapter = "INVALID_CHAPTER",
	LaunchInProgress = "LAUNCH_IN_PROGRESS",
	CountdownCancelled = "COUNTDOWN_CANCELLED",
	Cooldown = "PORTAL_COOLDOWN",
	ZoneRequired = "ZONE_REQUIRED",
	StateConflict = "STATE_CONFLICT",
}

function PortalTypes.ok(message: string, state: any?, data: any?): PortalResult
	return {
		ok = true,
		code = PortalTypes.ResultCode.Ok,
		message = message,
		state = state,
		data = data,
	}
end

function PortalTypes.err(code: string, message: string, state: any?, data: any?): PortalResult
	return {
		ok = false,
		code = code,
		message = message,
		state = state,
		data = data,
	}
end

return PortalTypes

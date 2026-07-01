--!strict
-- Shared types for Horror Orchestration.

local Types = {}

export type OrchestrationMode = "ApprovalOnly"
export type RequestKind =
	"MonsterIntent"
	| "DirectorPressure"
	| "ObservationPressure"
	| "GameplayPressure"
	| "NarrativeBeat"
	| "ReleaseRequest"
	| "ScareCandidate"
	| "ChasePreparation"
export type OrchestrationAction =
	"NoAction"
	| "Silence"
	| "Delay"
	| "Suppress"
	| "HoldPressure"
	| "Release"
	| "Escalate"
	| "CoordinateSensory"
	| "CoordinateEnvironment"
	| "CoordinateMonster"
	| "PrepareChase"

export type PressureRequest = {
	requestId: string,
	sourceSystem: string,
	requestKind: RequestKind,
	priority: number,
	pressure: number,
	createdAt: number,
	expiresAt: number,
	playerUserId: number?,
	partyId: string?,
	zoneId: string?,
	zoneKind: string?,
	meaning: string?,
	metadata: { [string]: any },
	tags: { string },
}

export type PressureBudget = {
	currentPressure: number,
	targetPressure: number,
	pressureDebt: number,
	releaseNeed: number,
	silenceNeed: number,
	chaseReadiness: number,
	sensoryLoad: number,
	emotionalLoad: number,
	multiplayerLoad: number,
}

export type CoordinationBundle = {
	bundleId: string,
	action: OrchestrationAction,
	requestId: string?,
	reasons: { string },
	createdAt: number,
	requests: { any },
	suppressed: boolean,
	delayed: boolean,
	releasePlanned: boolean,
	metadata: { [string]: any },
}

Types.ResultCode = {
	Ok = "OK",
	InvalidRequest = "INVALID_REQUEST",
	DuplicateRequest = "DUPLICATE_REQUEST",
	Expired = "EXPIRED",
	Queued = "QUEUED",
	Deferred = "DEFERRED",
	Suppressed = "SUPPRESSED",
}

return Types

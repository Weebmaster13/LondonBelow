--!strict
--[[
	Typed contracts for Monster Intelligence.

	These types describe believed knowledge, decaying memory, and intent
	requests. They deliberately omit movement, pathfinding, attacks, animations,
	and physical world mutation.
]]

local MonsterTypes = {}

export type MonsterState =
	"Dormant"
	| "Observing"
	| "Interested"
	| "Investigating"
	| "Waiting"
	| "Searching"
	| "Coordinating"
	| "Pressuring"
	| "Leaving"

export type IntentKind =
	"Observe"
	| "Investigate"
	| "Wait"
	| "Ignore"
	| "Prepare"
	| "Coordinate"
	| "Search"
	| "Pressure"
	| "Leave"

export type KnowledgeState = "Known" | "Suspected" | "Lost" | "False" | "Shared" | "Unknown"

export type MonsterDefinition = {
	monsterId: string,
	archetype: string,
	displayName: string?,
	territoryId: string?,
	tags: { string },
}

export type MonsterMemoryEntry = {
	id: string,
	monsterId: string,
	kind: string,
	subjectId: string?,
	zoneId: string?,
	confidence: number,
	createdAt: number,
	lastUpdatedAt: number,
	expiresAt: number?,
	metadata: { [string]: any },
}

export type MonsterKnowledgeEntry = {
	id: string,
	monsterId: string,
	fact: string,
	state: KnowledgeState,
	confidence: number,
	source: string,
	createdAt: number,
	lastUpdatedAt: number,
	metadata: { [string]: any },
}

export type InterestSignal = {
	id: string,
	monsterId: string,
	source: string,
	subjectId: string?,
	zoneId: string?,
	score: number,
	confidence: number,
	createdAt: number,
	reason: string,
	metadata: { [string]: any },
}

export type MonsterIntent = {
	intentId: string,
	monsterId: string,
	kind: IntentKind,
	targetPlayerId: string?,
	targetZoneId: string?,
	confidence: number,
	priority: number,
	reasons: { string },
	createdAt: number,
	expiresAt: number,
	metadata: { [string]: any },
}

export type MonsterDiagnostics = {
	initialized: boolean,
	started: boolean,
	monsterCount: number,
	memoryCount: number,
	knowledgeCount: number,
	claimCount: number,
	recentDecisions: { any },
	health: { healthy: boolean, status: string, message: string },
}

MonsterTypes.ResultCode = {
	Ok = "OK",
	InvalidRequest = "INVALID_REQUEST",
	DuplicateMonster = "DUPLICATE_MONSTER",
	UnknownMonster = "UNKNOWN_MONSTER",
	InvalidState = "INVALID_STATE",
	InvalidConfidence = "INVALID_CONFIDENCE",
	InvalidInterest = "INVALID_INTEREST",
	DuplicateClaim = "DUPLICATE_CLAIM",
	UnsafeRequest = "UNSAFE_REQUEST",
}

return MonsterTypes

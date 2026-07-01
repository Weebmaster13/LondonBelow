--!strict
--[[
	Shared Luau contracts for the London Engine Observation Engine.

	Owns stable data shapes for observation definitions, accepted observations,
	context snapshots, memory windows, aggregation summaries, patterns,
	timeline queries, and service inspection.

	Does not own gameplay logic, Monster AI, Horror Director interpretation,
	analytics export, client remotes, or presentation effects.

	Future systems should import these types when reporting server-trusted facts.
	Observations are server-authoritative knowledge objects; clients may cause
	validated gameplay events, but clients do not create trusted observations.
]]

local ObservationTypes = {}

export type ObservationCategory =
	"Movement"
	| "Camera"
	| "Interaction"
	| "Gameplay"
	| "Puzzle"
	| "Lantern"
	| "Environment"
	| "Monster"
	| "Social"
	| "Fear"
	| "Exploration"
	| "Story"
	| "Time"

export type AggregationRule = "Count" | "Duration" | "Latest" | "Unique" | "Route"
export type ExpirationWindow =
	"Immediate"
	| "TenSeconds"
	| "ThirtySeconds"
	| "OneMinute"
	| "FiveMinutes"
	| "TenMinutes"
	| "Chapter"
	| "Match"

export type ObservationDefinition = {
	id: string,
	category: ObservationCategory,
	description: string,
	expectedMetadata: { string },
	weight: number,
	priority: number,
	aggregation: AggregationRule,
	expiration: ExpirationWindow,
	directorKind: string?,
}

export type ObservationInput = {
	id: string,
	player: Player?,
	amount: number?,
	metadata: { [string]: any }?,
	source: string?,
	at: number?,
}

export type ObservationContext = {
	chapterId: string?,
	chapterPhase: string?,
	roomId: string?,
	areaId: string?,
	buildingZone: string?,
	weather: string?,
	lighting: string?,
	objectiveId: string?,
	puzzleId: string?,
	nearbyPlayerCount: number,
	nearbyMonsterCount: number,
	timeSinceLastScare: number?,
	tensionState: string?,
	areaTags: { string },
	roomTags: { string },
}

export type Observation = {
	sequence: number,
	id: string,
	category: ObservationCategory,
	player: Player?,
	userId: number?,
	amount: number,
	weight: number,
	priority: number,
	expiration: ExpirationWindow,
	metadata: { [string]: any },
	source: string,
	at: number,
	expiresAt: number?,
	context: ObservationContext,
}

export type Pattern = {
	id: string,
	userId: number?,
	confidence: number,
	description: string,
	observations: { string },
	at: number,
	expiresAt: number?,
}

export type PersonalitySnapshot = {
	userId: number,
	traits: { [string]: number },
	updatedAt: number,
}

export type TimelineQuery = {
	userId: number?,
	category: ObservationCategory?,
	since: number?,
	untilTime: number?,
	limit: number?,
}

export type AggregationSnapshot = {
	countsById: { [string]: number },
	countsByCategory: { [string]: number },
	countsByUserId: { [number]: number },
	recentHighPriority: { Observation },
}

export type ValidationResult = {
	ok: boolean,
	code: string,
	message: string,
}

export type ServiceInspection = {
	initialized: boolean,
	started: boolean,
	acceptedCount: number,
	rejectedCount: number,
	lastObservation: Observation?,
	memory: any,
	timeline: any,
	patterns: any,
	aggregates: AggregationSnapshot,
	profiler: any,
}

ObservationTypes.ExpirationSeconds = {
	Immediate = 0,
	TenSeconds = 10,
	ThirtySeconds = 30,
	OneMinute = 60,
	FiveMinutes = 300,
	TenMinutes = 600,
	Chapter = 1800,
	Match = 3600,
}

return ObservationTypes

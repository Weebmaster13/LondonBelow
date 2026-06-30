--!strict
--[[
	Shared type contract for the London Engine Psychological Horror Director.

	Owns exported Luau types and stable enum-like tables for tension states,
	chapter phases, and scare categories.

	Does not own runtime state, tuning values, persistence schemas, or scare
	selection behavior.

	Future systems should reuse these names instead of inventing ad hoc strings.
	These types describe server-owned data and are not a client-trusted input
	contract.
]]

local HorrorDirectorTypes = {}

export type TensionState = "Calm" | "Uneasy" | "Tense" | "Dread" | "Panic" | "Release"
export type ChapterPhase =
	"Lobby"
	| "Opening"
	| "Exploration"
	| "Puzzle"
	| "Threat"
	| "Climax"
	| "Escape"
export type ScareCategory =
	"Ambient"
	| "Psychological"
	| "Visual"
	| "Audio"
	| "Environmental"
	| "MonsterOpportunity"
	| "MajorClimax"

export type Observation = {
	player: Player?,
	userId: number?,
	kind: string,
	amount: number?,
	positionKey: string?,
	tags: { string }?,
	metadata: { [string]: any }?,
	at: number,
}

export type PlayerFearProfile = {
	userId: number,
	name: string,
	createdAt: number,
	updatedAt: number,
	timeAlone: number,
	timeWithParty: number,
	sprintCount: number,
	hideCount: number,
	lanternUseCount: number,
	darknessTime: number,
	lookBehindCount: number,
	doorHesitationCount: number,
	puzzleProgress: number,
	objectiveProgress: number,
	explorationDistance: number,
	repeatedRouteCount: number,
	repeatedHidingSpotCount: number,
	scaresSeen: number,
	lastScareAt: number,
	lastChaseAt: number,
	lastObservationAt: number,
	confidence: number,
	caution: number,
	curiosity: number,
	fearPressure: number,
	overwhelm: number,
	traits: { [string]: boolean },
	recentPositions: { string },
	recentHidingSpots: { string },
	recentScareIds: { string },
}

export type TensionSnapshot = {
	state: TensionState,
	score: number,
	pressure: number,
	release: number,
	partyState: TensionState,
	partyScore: number,
	reasons: { string },
}

export type ScareDefinition = {
	id: string,
	displayName: string,
	category: ScareCategory,
	intensity: number,
	baseWeight: number,
	cooldownSeconds: number,
	categoryCooldownSeconds: number,
	maxRepeats: number,
	supportsSolo: boolean,
	supportsGroup: boolean,
	allowedTension: { TensionState },
	allowedPhases: { ChapterPhase },
	tags: { string },
	requirements: { string },
}

export type DirectorDecision = {
	id: number,
	at: number,
	playerUserId: number?,
	scareId: string?,
	category: ScareCategory?,
	intensity: number,
	tensionState: TensionState,
	reason: string,
	silence: boolean,
	blocked: { string },
}

export type DirectorState = {
	started: boolean,
	chapterPhase: ChapterPhase,
	evaluationCount: number,
	lastEvaluationAt: number,
	lastDecision: DirectorDecision?,
}

HorrorDirectorTypes.TensionState = {
	Calm = "Calm",
	Uneasy = "Uneasy",
	Tense = "Tense",
	Dread = "Dread",
	Panic = "Panic",
	Release = "Release",
}

HorrorDirectorTypes.ChapterPhase = {
	Lobby = "Lobby",
	Opening = "Opening",
	Exploration = "Exploration",
	Puzzle = "Puzzle",
	Threat = "Threat",
	Climax = "Climax",
	Escape = "Escape",
}

HorrorDirectorTypes.ScareCategory = {
	Ambient = "Ambient",
	Psychological = "Psychological",
	Visual = "Visual",
	Audio = "Audio",
	Environmental = "Environmental",
	MonsterOpportunity = "MonsterOpportunity",
	MajorClimax = "MajorClimax",
}

return HorrorDirectorTypes

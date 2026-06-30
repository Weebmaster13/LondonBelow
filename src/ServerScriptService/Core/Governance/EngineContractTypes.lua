--!strict
--[[
	Shared contract types for the London Engine Governance Layer.

	Owns the stable schema every future subsystem can use to declare ownership,
	boundaries, observations, Director approvals, execution permissions,
	diagnostics, snapshots, cleanup, multiplayer guarantees, and failure modes.

	Does not own system behavior. Governance describes and validates architecture;
	it never implements gameplay, Monster AI, Chapter 1, UI, or art.
]]

local EngineContractTypes = {}

export type OwnerLayer =
	"Core"
	| "Lobby"
	| "Portal"
	| "Observation"
	| "Director"
	| "Execution"
	| "Gameplay"
	| "AI"
	| "ClientPresentation"
	| "Saving"
	| "Performance"
	| "Documentation"

export type SecurityLevel =
	"ServerOnly"
	| "ServerAuthoritative"
	| "ClientPresentation"
	| "SharedReadOnly"
export type ContractStatus = "Foundation" | "Production" | "Experimental" | "Deprecated"
export type GovernanceHealth = "NotValidated" | "Healthy" | "Warning" | "Failed"
export type ApprovalKind =
	"Horror"
	| "Narrative"
	| "Story"
	| "Environment"
	| "Lighting"
	| "Audio"
	| "Music"
	| "Monster"
	| "Puzzle"
	| "Save"
	| "Difficulty"
	| "Performance"

export type ObservationRule = {
	id: string,
	when: string,
	required: boolean,
}

export type DirectorApprovalRule = {
	director: ApprovalKind,
	reason: string,
	requiredFor: { string },
}

export type ExecutionPermission = {
	action: string,
	requiresApproval: boolean,
	approval: ApprovalKind?,
}

export type ClientPresentationRule = {
	allowed: boolean,
	description: string,
	mustBeServerApproved: boolean,
}

export type EngineContract = {
	systemName: string,
	ownerLayer: OwnerLayer,
	status: ContractStatus,
	responsibilities: { string },
	doesNotOwn: { string },
	dependencies: { string },
	observationsEmitted: { ObservationRule },
	directorApprovalsRequired: { DirectorApprovalRule },
	executionPermissions: { ExecutionPermission },
	clientPresentation: ClientPresentationRule,
	diagnosticsExposed: { string },
	snapshotProviders: { string },
	cleanupBehavior: { string },
	multiplayerGuarantees: { string },
	failureModes: { string },
	documentation: { string },
	tags: { string },
}

export type ContractIssue = {
	systemName: string,
	code: string,
	severity: "Pass" | "Info" | "Warning" | "Error" | "Fatal",
	message: string,
}

export type ScoreCategory =
	"singleResponsibility"
	| "serverAuthority"
	| "observationOutput"
	| "directorIntegration"
	| "diagnostics"
	| "snapshotSupport"
	| "cleanup"
	| "multiplayerSafety"
	| "documentation"
	| "extensibility"
	| "failureSafety"

export type Scorecard = {
	systemName: string,
	total: number,
	max: number,
	percentage: number,
	passed: boolean,
	grade: "Excellent" | "Good" | "Weak" | "Failing",
	categories: { [ScoreCategory]: number },
	notes: { string },
}

export type ValidationSummary = {
	health: GovernanceHealth,
	totalIssues: number,
	fatalIssues: number,
	errorIssues: number,
	warningIssues: number,
	infoIssues: number,
	lastValidatedAt: number,
}

EngineContractTypes.OwnerLayer = {
	Core = "Core",
	Lobby = "Lobby",
	Portal = "Portal",
	Observation = "Observation",
	Director = "Director",
	Execution = "Execution",
	Gameplay = "Gameplay",
	AI = "AI",
	ClientPresentation = "ClientPresentation",
	Saving = "Saving",
	Performance = "Performance",
	Documentation = "Documentation",
}

return EngineContractTypes

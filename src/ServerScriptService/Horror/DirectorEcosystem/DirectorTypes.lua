--!strict
--[[
	Shared contracts for the London Engine Director Ecosystem.

	The Director Ecosystem is architecture only. Directors interpret observations
	and request approvals; they do not execute gameplay, move monsters, play
	final audio, change final lighting, or render UI.
]]

local DirectorTypes = {}

export type DirectorName =
	"PsychologicalHorror"
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

export type DirectorHealthStatus =
	"NotInitialized"
	| "Ready"
	| "Running"
	| "Degraded"
	| "Failed"
	| "Stopped"
export type RequestPriority = "Low" | "Normal" | "High" | "Critical"
export type ApprovalState =
	"Pending"
	| "Approved"
	| "Rejected"
	| "Deferred"
	| "Modified"
	| "Expired"
	| "Cancelled"

export type DirectorCapability = {
	id: string,
	description: string,
	requestKinds: { string },
}

export type DirectorRequest = {
	id: string,
	timestamp: number,
	sourceDirector: DirectorName,
	targetDirector: DirectorName,
	kind: string,
	priority: RequestPriority,
	reason: string,
	supportingObservations: { any },
	context: { [string]: any },
	expiresAt: number?,
	approvalState: ApprovalState,
}

export type ApprovalResponse = {
	requestId: string,
	state: ApprovalState,
	reason: string,
	modifications: { [string]: any }?,
	decidedAt: number,
	decidedBy: string,
}

export type DirectorDescription = {
	name: DirectorName,
	displayName: string,
	responsibilities: { string },
	doesNotOwn: { string },
	capabilities: { DirectorCapability },
	priority: number,
}

export type DirectorHealth = {
	name: DirectorName,
	status: DirectorHealthStatus,
	healthy: boolean,
	message: string?,
	uptime: number,
	lastError: string?,
}

export type Director = {
	Initialize: (self: Director) -> (),
	Start: (self: Director) -> (),
	Shutdown: (self: Director) -> (),
	Observe: (self: Director, observation: any) -> (),
	RequestApproval: (self: Director, request: DirectorRequest) -> ApprovalResponse,
	CancelRequest: (self: Director, requestId: string, reason: string?) -> ApprovalResponse,
	GetHealth: (self: Director) -> DirectorHealth,
	GetSnapshot: (self: Director) -> any,
	GetDiagnostics: (self: Director) -> any,
	GetCapabilities: (self: Director) -> { DirectorCapability },
	Validate: (self: Director) -> (boolean, string?),
	Describe: (self: Director) -> DirectorDescription,
}

DirectorTypes.PriorityWeight = {
	Low = 1,
	Normal = 2,
	High = 3,
	Critical = 4,
}

DirectorTypes.ApprovalState = {
	Pending = "Pending",
	Approved = "Approved",
	Rejected = "Rejected",
	Deferred = "Deferred",
	Modified = "Modified",
	Expired = "Expired",
	Cancelled = "Cancelled",
}

return DirectorTypes

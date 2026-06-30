--!strict
--[[
	Stable Director Ecosystem types for London Engine.

	Directors interpret Observation Engine truth and request approvals. They do
	not execute physical gameplay or client presentation.
]]

local DirectorTypes = {}

export type DirectorName = string

export type RequestPriority = "Low" | "Normal" | "High" | "Critical"
export type ApprovalStatus =
	"Approved"
	| "Rejected"
	| "Deferred"
	| "Modified"
	| "Expired"
	| "Cancelled"
export type DirectorHealthStatus =
	"NotInitialized"
	| "Ready"
	| "Running"
	| "Degraded"
	| "Failed"
	| "Stopped"

export type DirectorCapability = {
	id: string,
	description: string,
	requestKinds: { string },
}

export type DirectorRequest = {
	requestId: string,
	sourceDirector: DirectorName,
	targetDirector: DirectorName,
	requestKind: string,
	priority: RequestPriority,
	reason: string,
	createdAt: number,
	expiresAt: number,
	supportingObservationIds: { string },
	context: { [string]: any },
	metadata: { [string]: any },
	requiresApproval: boolean,
	conflictGroup: string?,
	tags: { string },
}

export type DirectorApproval = {
	requestId: string,
	status: ApprovalStatus,
	reason: string,
	decidedBy: string,
	decidedAt: number,
	modifiedRequest: DirectorRequest?,
	diagnostics: { [string]: any },
}

export type DirectorHealth = {
	name: DirectorName,
	status: DirectorHealthStatus,
	healthy: boolean,
	message: string?,
	uptime: number,
	lastError: string?,
}

export type DirectorDescription = {
	name: DirectorName,
	displayName: string,
	responsibilities: { string },
	doesNotOwn: { string },
	capabilities: { DirectorCapability },
}

export type Director = {
	initialize: (self: Director) -> (),
	start: (self: Director) -> (),
	shutdown: (self: Director) -> (),
	observe: (self: Director, observation: any) -> (),
	requestApproval: (self: Director, request: DirectorRequest) -> DirectorApproval,
	cancelRequest: (self: Director, requestId: string, reason: string?) -> DirectorApproval,
	getCapabilities: (self: Director) -> { DirectorCapability },
	getHealth: (self: Director) -> DirectorHealth,
	getSnapshot: (self: Director) -> any,
	getDiagnostics: (self: Director) -> any,
	validate: (self: Director) -> (boolean, string?),
	describe: (self: Director) -> DirectorDescription,
}

DirectorTypes.PriorityWeight = {
	Low = 1,
	Normal = 2,
	High = 3,
	Critical = 4,
}

DirectorTypes.ValidApprovalStatuses = {
	Approved = true,
	Rejected = true,
	Deferred = true,
	Modified = true,
	Expired = true,
	Cancelled = true,
}

DirectorTypes.ValidHealthStatuses = {
	NotInitialized = true,
	Ready = true,
	Running = true,
	Degraded = true,
	Failed = true,
	Stopped = true,
}

return DirectorTypes

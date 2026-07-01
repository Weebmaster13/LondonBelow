--!strict
--[[
	Contracts for the Gameplay Execution Bridge.

	Execution requests are server-owned instructions for future physical or
	presentation adapters. They never create gameplay truth, never bypass
	Directors, and never imply that Workspace mutation is enabled.
]]

local GameplayExecutionTypes = {}

export type ExecutionMode = "Disabled" | "DryRun" | "Enabled"
export type ExecutionStatus =
	"Pending"
	| "Validated"
	| "Rejected"
	| "Deferred"
	| "Applied"
	| "Failed"
	| "Cancelled"
	| "Expired"

export type ExecutionRequest = {
	executionId: string,
	sourceSystem: string,
	targetObjectId: string,
	executionKind: string,
	requestedState: string?,
	approvedBy: string?,
	approvalId: string?,
	gameplayFactId: string?,
	priority: number,
	createdAt: number,
	expiresAt: number,
	payload: { [string]: any },
	metadata: { [string]: any },
	tags: { string },
}

export type ExecutionRecord = {
	request: ExecutionRequest,
	status: ExecutionStatus,
	reason: string?,
	updatedAt: number,
}

export type ExecutionAdapter = {
	canApply: (ExecutionRequest) -> (boolean, string?),
	apply: (ExecutionRequest) -> (boolean, string?),
	rollback: (ExecutionRequest) -> (boolean, string?),
	getHealth: () -> any,
	getDiagnostics: () -> any,
	describe: () -> string,
}

GameplayExecutionTypes.ResultCode = {
	Ok = "OK",
	InvalidRequest = "INVALID_REQUEST",
	DuplicateExecution = "DUPLICATE_EXECUTION",
	UnknownExecutionKind = "UNKNOWN_EXECUTION_KIND",
	MissingTarget = "MISSING_TARGET",
	Expired = "EXPIRED",
	Deferred = "DEFERRED",
	Failed = "FAILED",
	Disabled = "DISABLED",
	DryRun = "DRY_RUN",
}

return GameplayExecutionTypes

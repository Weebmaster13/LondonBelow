--!strict
--[[
	Shared contracts for the Gameplay Intelligence Framework.

	These types describe reusable gameplay truth only. They do not describe
	Chapter 1 content, final UI, final art, final scares, Monster AI, or
	physical Workspace mutation.
]]

local GameplayTypes = {}

export type Result = {
	ok: boolean,
	code: string,
	message: string,
	data: any?,
}

export type GameplayEvent = {
	id: string,
	kind: string,
	source: string,
	playerUserId: number?,
	objectId: string?,
	metadata: { [string]: any },
	at: number,
}

export type GameplayDefinition = {
	id: string,
	kind: string,
	ownerSystem: string,
	description: string,
	dependencies: { string },
	observations: { string },
	directorHooks: { string },
	metadata: { [string]: any },
}

export type RuntimeHealth = {
	healthy: boolean,
	status: string,
	message: string,
}

GameplayTypes.ResultCode = {
	Ok = "OK",
	InvalidRequest = "INVALID_REQUEST",
	DuplicateId = "DUPLICATE_ID",
	UnknownId = "UNKNOWN_ID",
	InvalidState = "INVALID_STATE",
	MissingDependency = "MISSING_DEPENDENCY",
	PermissionDenied = "PERMISSION_DENIED",
	ServerError = "SERVER_ERROR",
}

return GameplayTypes

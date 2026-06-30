--!strict
--[[
	Lantern gameplay truth contracts.

	These types describe server-owned lantern state. They do not define final
	assets, final lighting effects, final UI, audio playback, or client-owned
	fear/darkness truth.
]]

local LanternTypes = {}

export type LanternStatus = {
	userId: number,
	equipped: boolean,
	on: boolean,
	battery: number,
	overuseScore: number,
	lastToggleAt: number,
	lastObservationAt: number,
	zoneId: string,
	zoneKind: string,
	protected: boolean,
}

export type ToggleRequest = {
	requestId: string?,
	on: boolean?,
	equipped: boolean?,
	zoneId: string?,
	zoneKind: string?,
	metadata: { [string]: any }?,
}

export type LanternResult = {
	ok: boolean,
	code: string,
	message: string,
	status: LanternStatus?,
}

LanternTypes.ResultCode = {
	Ok = "OK",
	InvalidRequest = "INVALID_REQUEST",
	RateLimited = "RATE_LIMITED",
	NotEquipped = "NOT_EQUIPPED",
	ServerError = "SERVER_ERROR",
}

return LanternTypes

--!strict
--[[
	Darkness gameplay truth contracts.

	Darkness truth is server-owned. Clients may later present approved effects,
	but they do not decide darkness exposure or fear state.
]]

local DarknessTypes = {}

export type ExposureState = {
	userId: number,
	inDarkness: boolean,
	exposure: number,
	enteredAt: number?,
	lastUpdatedAt: number,
	lastExposureObservationAt: number,
	lastDirectorRequestAt: number,
	zoneId: string,
	zoneKind: string,
	protected: boolean,
}

export type DarknessContext = {
	zoneId: string?,
	zoneKind: string?,
	intensity: number?,
	metadata: { [string]: any }?,
}

return DarknessTypes

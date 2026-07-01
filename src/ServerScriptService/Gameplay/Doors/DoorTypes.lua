--!strict

local DoorTypes = {}

export type DoorState =
	"Open"
	| "Closed"
	| "Locked"
	| "Unlocked"
	| "Bolted"
	| "Barred"
	| "Jammed"
	| "Broken"
	| "PowerLocked"
	| "PuzzleLocked"
	| "DirectorLocked"
	| "NarrativeLocked"
	| "Opening"
	| "Closing"
	| "Sealed"
	| "Disabled"

export type DoorDefinition = {
	id: string,
	displayName: string,
	initialState: DoorState,
	requiredKeyIds: { string },
	allowedUsers: { number },
	metadata: { [string]: any },
}

export type DoorStatus = {
	id: string,
	state: DoorState,
	lastChangedAt: number,
	openAttempts: number,
	failedAttempts: number,
	metadata: { [string]: any },
}

return DoorTypes

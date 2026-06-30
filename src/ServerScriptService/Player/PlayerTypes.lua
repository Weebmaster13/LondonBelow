--!strict
--[[
	Server-side player runtime contracts for London Engine.

	The Player Runtime owns authoritative player lifecycle state, movement mode,
	lock flags, and future chapter context hooks. It does not own camera
	presentation, final stamina, fear, injury, save data, Monster AI, or chapter
	content.
]]

local PlayerTypes = {}

export type LifecycleState = "Alive" | "Dead" | "Spectating"
export type GroundState = "Grounded" | "Airborne"
export type MovementMode = "Walk" | "Sprint" | "Crouch" | "Stopped"

export type PlayerRuntimeState = {
	userId: number,
	lifecycleState: LifecycleState,
	groundState: GroundState,
	movementMode: MovementMode,
	interactionLocked: boolean,
	cinematicLocked: boolean,
	currentRoomId: string?,
	currentAreaId: string?,
	currentChapterId: string?,
	movementRestrictions: { string },
	stamina: number?,
	fear: number?,
	injury: number?,
	updatedAt: number,
}

export type PlayerStatePatch = {
	lifecycleState: LifecycleState?,
	groundState: GroundState?,
	movementMode: MovementMode?,
	interactionLocked: boolean?,
	cinematicLocked: boolean?,
	currentRoomId: string?,
	currentAreaId: string?,
	currentChapterId: string?,
	movementRestrictions: { string }?,
	stamina: number?,
	fear: number?,
	injury: number?,
}

PlayerTypes.LifecycleState = {
	Alive = "Alive",
	Dead = "Dead",
	Spectating = "Spectating",
}

PlayerTypes.GroundState = {
	Grounded = "Grounded",
	Airborne = "Airborne",
}

PlayerTypes.MovementMode = {
	Walk = "Walk",
	Sprint = "Sprint",
	Crouch = "Crouch",
	Stopped = "Stopped",
}

return PlayerTypes

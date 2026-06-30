--!strict
--[[
	Shared contracts for the London Engine Player Experience Foundation.

	These types describe client requests, server responses, movement profiles,
	interaction focus, feedback hooks, and reusable object interaction metadata.

	The server owns trusted gameplay outcomes. Clients may discover focus,
	request interactions, render prompts, and apply presentation-only feedback.
]]

local PlayerExperienceTypes = {}

export type MovementMode = "Walk" | "Sprint" | "Crouch" | "Airborne"
export type InteractionKind =
	"Door"
	| "Drawer"
	| "Cabinet"
	| "Switch"
	| "Lever"
	| "Collectible"
	| "Note"
	| "Key"
	| "Generic"

export type FeedbackKind = "Audio" | "Visual" | "Prompt" | "Haptics" | "ScreenEffect"

export type MovementProfile = {
	id: string,
	walkSpeed: number,
	sprintSpeed: number,
	crouchSpeed: number,
	jumpPower: number,
	allowSprint: boolean,
	allowCrouch: boolean,
	allowJump: boolean,
	staminaEnabled: boolean,
	cameraHeight: number,
	crouchCameraHeight: number,
}

export type InteractionDescriptor = {
	id: string,
	kind: InteractionKind,
	instance: Instance?,
	prompt: string,
	priority: number,
	maxDistance: number,
	requiresLineOfSight: boolean,
	cooperative: boolean,
	replayable: boolean,
	enabled: boolean,
	observationId: string?,
	metadata: { [string]: any },
}

export type InteractionRequest = {
	interactionId: string,
	target: Instance?,
	clientFocusId: string?,
	clientDistance: number?,
	inputKind: string?,
	requestId: string?,
}

export type InteractionResult = {
	ok: boolean,
	code: string,
	message: string,
	interaction: InteractionDescriptor?,
	feedback: { FeedbackInstruction },
}

export type FocusPayload = {
	interactionId: string?,
	prompt: string?,
	kind: InteractionKind?,
	priority: number?,
	maxDistance: number?,
	metadata: { [string]: any }?,
}

export type FeedbackInstruction = {
	kind: FeedbackKind,
	id: string,
	intensity: number,
	duration: number?,
	metadata: { [string]: any }?,
}

export type PlayerInputState = {
	sprinting: boolean,
	crouching: boolean,
	jumping: boolean,
	movementMode: MovementMode,
}

PlayerExperienceTypes.ResultCode = {
	Ok = "OK",
	InvalidRequest = "INVALID_REQUEST",
	NotReady = "NOT_READY",
	UnknownInteraction = "UNKNOWN_INTERACTION",
	InteractionDisabled = "INTERACTION_DISABLED",
	OutOfRange = "OUT_OF_RANGE",
	LineOfSightBlocked = "LINE_OF_SIGHT_BLOCKED",
	PermissionDenied = "PERMISSION_DENIED",
	ServerError = "SERVER_ERROR",
}

return PlayerExperienceTypes

--!strict

local ObjectTypes = {}

export type ObjectKind =
	"Door"
	| "Drawer"
	| "Cabinet"
	| "Lever"
	| "Valve"
	| "Switch"
	| "Book"
	| "Note"
	| "Painting"
	| "Statue"
	| "Mirror"
	| "Clock"
	| "Bell"
	| "Window"
	| "Rope"
	| "Chain"
	| "Generator"
	| "FuseBox"
	| "Elevator"
	| "Crank"
	| "PressurePlate"
	| "Pedestal"
	| "Artifact"
	| "Safe"
	| "Chest"
	| "Gate"
	| "SecretPassage"
	| "HiddenWall"
	| "Custom"

export type ObjectDefinition = {
	id: string,
	kind: ObjectKind,
	ownerSystem: string,
	allowedStates: { string },
	initialState: string,
	interactionPermissions: { [string]: boolean },
	dependencies: { string },
	observationsEmitted: { string },
	directorRequestHooks: { string },
	metadata: { [string]: any },
}

export type ObjectStatus = {
	id: string,
	kind: ObjectKind,
	state: string,
	lastChangedAt: number,
	metadata: { [string]: any },
}

ObjectTypes.AllowedKinds = {
	"Door",
	"Drawer",
	"Cabinet",
	"Lever",
	"Valve",
	"Switch",
	"Book",
	"Note",
	"Painting",
	"Statue",
	"Mirror",
	"Clock",
	"Bell",
	"Window",
	"Rope",
	"Chain",
	"Generator",
	"FuseBox",
	"Elevator",
	"Crank",
	"PressurePlate",
	"Pedestal",
	"Artifact",
	"Safe",
	"Chest",
	"Gate",
	"SecretPassage",
	"HiddenWall",
	"Custom",
}

return ObjectTypes

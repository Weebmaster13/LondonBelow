--!strict

local ObjectiveTypes = {}

export type ObjectiveKind =
	"Primary"
	| "Secondary"
	| "Hidden"
	| "Personal"
	| "Party"
	| "Branching"
	| "Timed"

export type ObjectiveDefinition = {
	id: string,
	kind: ObjectiveKind,
	displayName: string,
	steps: { string },
	branchIds: { string },
	metadata: { [string]: any },
}

export type ObjectiveStatus = {
	id: string,
	started: boolean,
	completed: boolean,
	failed: boolean,
	progress: number,
	currentStep: string?,
}

return ObjectiveTypes

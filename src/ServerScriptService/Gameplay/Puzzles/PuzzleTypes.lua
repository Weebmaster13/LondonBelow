--!strict

local PuzzleTypes = {}

export type PuzzleNode = {
	id: string,
	dependencies: { string },
	requiredItems: { string },
	requiredObjectStates: { [string]: string },
	cooperative: boolean,
	metadata: { [string]: any },
}

export type PuzzleDefinition = {
	id: string,
	displayName: string,
	nodes: { PuzzleNode },
	failStates: { string },
	completionNodeIds: { string },
	hints: { string },
	fairnessProtection: boolean,
	directorRequestHooks: { string },
	metadata: { [string]: any },
}

return PuzzleTypes

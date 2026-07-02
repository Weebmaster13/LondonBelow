--!strict
-- Shared constants for Phase 24 Puzzle Runtime Foundation.

local Types = {}

Types.Mode = "ServerAuthoritativePuzzleSchemaRuntime"

Types.PuzzleType = {
	PuzzleSchema = "PuzzleSchema",
	PuzzleNodeSchema = "PuzzleNodeSchema",
	PuzzleEdgeSchema = "PuzzleEdgeSchema",
	PuzzleConditionSchema = "PuzzleConditionSchema",
	PuzzleDependencySchema = "PuzzleDependencySchema",
	PuzzleSequenceSchema = "PuzzleSequenceSchema",
	PuzzleStateSchema = "PuzzleStateSchema",
	PuzzleProgressSchema = "PuzzleProgressSchema",
	SystemPuzzleSchema = "SystemPuzzleSchema",
}

Types.ResultCode = {
	Ok = "Ok",
	InvalidRequest = "InvalidRequest",
	DuplicatePuzzle = "DuplicatePuzzle",
	UnknownPuzzle = "UnknownPuzzle",
	UnsafePayload = "UnsafePayload",
}

Types.Limits = {
	MaxPuzzles = 320,
	MaxNodes = 1200,
	MaxNodesPerPuzzle = 120,
	MaxGraphs = 320,
	MaxDependencies = 800,
	MaxDependenciesPerPuzzle = 80,
	MaxConditions = 800,
	MaxConditionsPerPuzzle = 80,
	MaxEdgesPerPuzzle = 240,
	MaxProgressRecords = 500,
	MaxValidationFailures = 180,
	MaxSnapshotHistory = 80,
	MaxPayloadDepth = 8,
	MaxPayloadNodes = 280,
	MaxPayloadStringLength = 512,
	MaxTags = 24,
}

return Types

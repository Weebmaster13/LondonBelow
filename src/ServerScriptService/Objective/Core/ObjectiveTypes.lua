--!strict
-- Shared constants for Phase 27 Objective Runtime Foundation.

local Types = {}

Types.Mode = "ServerAuthoritativeObjectiveSchemaRuntime"

Types.SchemaType = {
	ObjectiveSchema = "ObjectiveSchema",
	TaskSchema = "TaskSchema",
	RequirementSchema = "RequirementSchema",
	DependencySchema = "DependencySchema",
	ObjectiveStateSchema = "ObjectiveStateSchema",
	ObjectiveProgressSchema = "ObjectiveProgressSchema",
	SystemObjectiveSchema = "SystemObjectiveSchema",
}

Types.ResultCode = {
	Ok = "Ok",
	InvalidRequest = "InvalidRequest",
	DuplicateObjective = "DuplicateObjective",
	UnknownObjective = "UnknownObjective",
	UnsafePayload = "UnsafePayload",
}

Types.Limits = {
	MaxObjectives = 800,
	MaxTasks = 3200,
	MaxRequirements = 3200,
	MaxDependencies = 2400,
	MaxProgressRecords = 2000,
	MaxTasksPerObjective = 120,
	MaxRequirementsPerObjective = 120,
	MaxDependenciesPerObjective = 120,
	MaxTags = 32,
	MaxValidationFailures = 220,
	MaxSnapshotHistory = 80,
	MaxPayloadDepth = 9,
	MaxPayloadNodes = 360,
	MaxPayloadStringLength = 640,
}

return Types

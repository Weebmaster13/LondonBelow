--!strict
-- Shared constants for the Chapter 0 Gameplay Flow Runtime.

local Types = {}

Types.RuntimeName = "GameplayFlowRuntime"
Types.ProviderName = "gameplayFlowRuntime"
Types.ChapterId = "chapter0.home"

Types.ObjectiveState = {
	Locked = "Locked",
	Available = "Available",
	Active = "Active",
	Completed = "Completed",
	Failed = "Failed",
	Skipped = "Skipped",
}

Types.ConditionKind = {
	InteractionCompleted = "InteractionCompleted",
	EnvironmentalState = "EnvironmentalState",
	InspectionCompleted = "InspectionCompleted",
	BinaryMechanismState = "BinaryMechanismState",
	PresentationAcknowledged = "PresentationAcknowledged",
	RuntimeEvent = "RuntimeEvent",
	ObjectiveCompleted = "ObjectiveCompleted",
}

Types.EventKind = {
	ObjectiveActivated = "ObjectiveActivated",
	ObjectiveCompleted = "ObjectiveCompleted",
	ObjectiveFailed = "ObjectiveFailed",
	ObjectiveSkipped = "ObjectiveSkipped",
	CheckpointUnlocked = "CheckpointUnlocked",
	ObjectiveChanged = "ObjectiveChanged",
	ProgressUpdated = "ProgressUpdated",
	GameplayEvent = "GameplayEvent",
	CheckpointEligible = "CheckpointEligible",
}

Types.PrerequisiteMode = {
	And = "AND",
	Or = "OR",
}

Types.ResultCode = {
	Ok = "Ok",
	InvalidRequest = "InvalidRequest",
	DuplicateObjective = "DuplicateObjective",
	UnknownObjective = "UnknownObjective",
	InvalidGraph = "InvalidGraph",
	InvalidCondition = "InvalidCondition",
	InvalidState = "InvalidState",
	UnsafePayload = "UnsafePayload",
	RuntimeUnavailable = "RuntimeUnavailable",
}

Types.Limits = {
	MaxObjectives = 64,
	MaxConditionsPerObjective = 16,
	MaxPrerequisitesPerObjective = 16,
	MaxNextObjectivesPerObjective = 16,
	MaxOptionalObjectivesPerObjective = 16,
	MaxEvents = 160,
	MaxEvidence = 220,
	MaxSnapshots = 80,
	MaxTransitions = 180,
	MaxValidationFailures = 120,
	MaxEvaluationQueue = 80,
	MaxGraphDepth = 16,
	MaxStringLength = 512,
	MaxTags = 24,
	MaxMetadataKeys = 32,
}

return Types

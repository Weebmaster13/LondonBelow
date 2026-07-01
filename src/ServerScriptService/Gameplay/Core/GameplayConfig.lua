--!strict

local GameplayConfig = {
	RecentEventLimit = 160,
	MemoryLimit = 220,
	MaxSerializedStateBytes = 250000,
	MaxRegisteredDefinitions = 1000,
	MaxDependenciesPerDefinition = 24,
	MaxInventoryItemsPerPlayer = 120,
	MaxPuzzleNodes = 300,
	MaxObjectiveSteps = 80,
	MaxRecentDiagnosticItems = 120,
	ObservationSource = "GameplayCoordinator",
	DirectorRequestCooldownSeconds = 3,
}

return GameplayConfig

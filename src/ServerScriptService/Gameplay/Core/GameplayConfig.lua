--!strict

local GameplayConfig = {
	RecentEventLimit = 160,
	MemoryLimit = 220,
	MaxRegisteredDefinitions = 1000,
	MaxDependenciesPerDefinition = 24,
	ObservationSource = "GameplayCoordinator",
	DirectorRequestCooldownSeconds = 3,
}

return GameplayConfig

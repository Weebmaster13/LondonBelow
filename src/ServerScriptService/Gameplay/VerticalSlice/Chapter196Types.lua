--!strict

local Types = {}

Types.RuntimeName = "Chapter196VerticalSliceCoordinator"
Types.RuntimeVersion = "196.0.0"
Types.State = table.freeze({
	Dormant = "Dormant",
	Building = "Building",
	Ready = "Ready",
	Running = "Running",
	Completed = "Completed",
	Shutdown = "Shutdown",
})
Types.InteractionKind = table.freeze({
	Lantern = "Lantern",
	Note = "Note",
	Collectible = "Collectible",
	Ward = "Ward",
	Door = "Door",
	Relic = "Relic",
	Escape = "Escape",
})
Types.Failure = table.freeze({
	InvalidDefinition = "InvalidDefinition",
	WorldBuildFailed = "WorldBuildFailed",
	InvalidPlayer = "InvalidPlayer",
	OutOfRange = "OutOfRange",
	WrongOrder = "WrongOrder",
	AlreadyCompleted = "AlreadyCompleted",
	MissingItem = "MissingItem",
	RuntimeUnavailable = "RuntimeUnavailable",
})
Types.Limits =
	table.freeze({ MaxAudit = 512, MaxFailures = 128, MaxInteractions = 32, MaxPlayers = 20 })

return table.freeze(Types)

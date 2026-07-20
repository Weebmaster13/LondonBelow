--!strict

local ServerScriptService = game:GetService("ServerScriptService")

local EnvironmentalTypes = require(ServerScriptService.Interaction.Environmental.EnvironmentalTypes)

local Types = {}

Types.RuntimeName = "Chapter0EnvironmentalBinding"
Types.ProviderName = "chapter0EnvironmentalRuntime"
Types.CoordinatorName = "Chapter0EnvironmentalCoordinator"
Types.SchemaVersion = 1
Types.ChapterId = "chapter_0_home"

Types.BindingStatus = {
	Unbound = "Unbound",
	Bound = "Bound",
	Blocked = "Blocked",
	Reconciled = "Reconciled",
	Reset = "Reset",
}

Types.ReadinessStatus = {
	Ready = "Ready",
	Blocked = "Blocked",
	Resetting = "Resetting",
	NotInitialized = "NotInitialized",
}

Types.ResultCode = {
	Ok = "OK",
	InvalidFixture = "INVALID_CHAPTER0_FIXTURE",
	DuplicateFixtureId = "DUPLICATE_CHAPTER0_FIXTURE_ID",
	MissingFixture = "MISSING_CHAPTER0_FIXTURE",
	MissingAuthoredInstance = "MISSING_AUTHORED_INSTANCE",
	BindingFailed = "CHAPTER0_ENVIRONMENTAL_BINDING_FAILED",
	BatchRollback = "CHAPTER0_ENVIRONMENTAL_BATCH_ROLLBACK",
	ReconciliationFailed = "CHAPTER0_ENVIRONMENTAL_RECONCILIATION_FAILED",
	RuntimeUnavailable = "CHAPTER0_ENVIRONMENTAL_RUNTIME_UNAVAILABLE",
}

Types.FixtureFamily = EnvironmentalTypes.Family
Types.EnvironmentalAction = EnvironmentalTypes.Action
Types.EnvironmentalState = EnvironmentalTypes.State

Types.Limits = {
	MaxFixtures = 32,
	MaxFixtureFamilies = 8,
	MaxFailures = 80,
	MaxEvidence = 120,
	MaxSnapshots = 60,
	MaxResetOperations = 16,
	MaxStringLength = 512,
}

return Types

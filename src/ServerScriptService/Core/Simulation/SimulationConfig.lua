--!strict

local SimulationConfig = {}

SimulationConfig.Mode = "Disabled"
SimulationConfig.MaxReports = 20
SimulationConfig.MaxTraceEvents = 250
SimulationConfig.SyntheticUserIdStart = -9000
SimulationConfig.ScenarioTimeoutSeconds = 10

SimulationConfig.ValidModes = {
	Disabled = true,
	SelfCheck = true,
	Manual = true,
}

SimulationConfig.RequiredScenarioIds = {
	"IdleSilence",
	"SpeedrunnerPressure",
	"LanternOveruse",
	"NoteIgnorer",
	"PartySplit",
	"ExecutionBridgeFailure",
	"InvalidObservation",
	"StaleZoneCleanup",
}

return SimulationConfig

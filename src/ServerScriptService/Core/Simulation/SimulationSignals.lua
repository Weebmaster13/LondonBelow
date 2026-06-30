--!strict

local SimulationSignals = {}

SimulationSignals.ModeChanged = "Simulation.ModeChanged"
SimulationSignals.ScenarioStarted = "Simulation.ScenarioStarted"
SimulationSignals.ScenarioCompleted = "Simulation.ScenarioCompleted"
SimulationSignals.ReportBuilt = "Simulation.ReportBuilt"
SimulationSignals.ValidationFailed = "Simulation.ValidationFailed"
SimulationSignals.TraceRecorded = "Simulation.TraceRecorded"

return SimulationSignals

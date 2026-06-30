--!strict

local Types = require(script.Parent.SimulationTypes)

local SimulationReportBuilder = {}

type SimulationReport = Types.SimulationReport
type SimulationScenario = Types.SimulationScenario

function SimulationReportBuilder.new(scenario: SimulationScenario): SimulationReport
	return {
		scenarioId = scenario.id,
		status = "Pass",
		warnings = {},
		failures = {},
		simulatedPlayers = table.clone(scenario.players),
		simulatedZones = table.clone(scenario.zones),
		observationsInjected = {},
		observationsRejected = {},
		pressureTimeline = {},
		candidateDecisions = {},
		rejectedDecisions = {},
		approvedDecisions = {},
		failedExecutionBridgeCalls = {},
		cooldownChanges = {},
		memoryChanges = {},
		diagnosticsSnapshots = {},
		architecturalViolations = {},
		decisionTraces = {},
	}
end

function SimulationReportBuilder.warn(report: SimulationReport, message: string)
	table.insert(report.warnings, message)

	if report.status == "Pass" then
		report.status = "Warning"
	end
end

function SimulationReportBuilder.fail(report: SimulationReport, message: string)
	table.insert(report.failures, message)
	report.status = "Fail"
end

return SimulationReportBuilder

--!strict

local Types = require(script.Parent.SimulationTypes)

local SimulationReportBuilder = {}

type SimulationReport = Types.SimulationReport
type SimulationScenario = Types.SimulationScenario

function SimulationReportBuilder.new(scenario: SimulationScenario, runId: string): SimulationReport
	local startedAt = os.clock()

	return {
		runId = runId,
		scenarioId = scenario.id,
		status = "Pass",
		startedAt = startedAt,
		completedAt = nil,
		durationSeconds = 0,
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
		cleanupResult = nil,
	}
end

function SimulationReportBuilder.complete(report: SimulationReport)
	report.completedAt = os.clock()
	report.durationSeconds = report.completedAt - report.startedAt
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

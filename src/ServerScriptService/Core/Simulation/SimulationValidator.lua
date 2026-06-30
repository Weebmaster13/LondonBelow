--!strict

local Config = require(script.Parent.SimulationConfig)
local ReportBuilder = require(script.Parent.SimulationReportBuilder)
local Registry = require(script.Parent.SimulationRegistry)
local Types = require(script.Parent.SimulationTypes)

local SimulationValidator = {}

type SimulationReport = Types.SimulationReport

local function count(values: { any }): number
	return #values
end

function SimulationValidator.validateRegistry(): (boolean, string?)
	return Registry.validate()
end

function SimulationValidator.validateReport(report: SimulationReport): SimulationReport
	for _, pressure in ipairs(report.pressureTimeline) do
		if type(pressure.score) == "number" and (pressure.score < -1 or pressure.score > 1) then
			ReportBuilder.fail(report, "Pressure escaped bounds")
		end
	end

	if count(report.memoryChanges) > Config.MaxTraceEvents then
		ReportBuilder.fail(report, "Simulation memory report exceeded trace limit")
	end

	if report.scenarioId == "InvalidObservation" and #report.observationsRejected == 0 then
		ReportBuilder.fail(report, "Invalid observation was not rejected")
	end

	if report.scenarioId == "ExecutionBridgeFailure" then
		if #report.failedExecutionBridgeCalls == 0 then
			ReportBuilder.fail(report, "Failed execution bridge call was not recorded")
		end

		if #report.cooldownChanges > 0 then
			ReportBuilder.fail(report, "Failed bridge request created cooldown state")
		end
	end

	if
		#report.rejectedDecisions > 0
		and #report.approvedDecisions == 0
		and #report.cooldownChanges > 0
	then
		ReportBuilder.fail(report, "Rejected decisions changed cooldown state")
	end

	if report.scenarioId == "StaleZoneCleanup" and #report.architecturalViolations > 0 then
		ReportBuilder.fail(report, "Stale zone cleanup left violations")
	end

	if #report.diagnosticsSnapshots == 0 then
		ReportBuilder.warn(report, "No diagnostics snapshots were captured")
	end

	if #report.decisionTraces == 0 and report.scenarioId ~= "IdleSilence" then
		ReportBuilder.warn(report, "No decision traces were recorded")
	end

	return report
end

return SimulationValidator

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

local function hasTraceEntries(report: SimulationReport): boolean
	for _, traceGroup in ipairs(report.decisionTraces) do
		if
			type(traceGroup) == "table"
			and type(traceGroup.traces) == "table"
			and #traceGroup.traces > 0
		then
			return true
		end
	end

	return false
end

local function hasChangedCooldown(report: SimulationReport): boolean
	for _, change in ipairs(report.cooldownChanges) do
		if type(change) == "table" and change.changed == true then
			return true
		end
	end

	return false
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

	if report.scenarioId == "IdleSilence" then
		if
			#report.observationsInjected > 0
			or #report.approvedDecisions > 0
			or hasChangedCooldown(report)
		then
			ReportBuilder.fail(report, "Idle silence produced activity")
		end
	elseif report.scenarioId == "SpeedrunnerPressure" then
		if #report.pressureTimeline == 0 or #report.approvedDecisions == 0 then
			ReportBuilder.fail(report, "Speedrunner pressure lacked pressure or approval evidence")
		end
	elseif report.scenarioId == "LanternOveruse" then
		if #report.observationsInjected < 3 or #report.candidateDecisions == 0 then
			ReportBuilder.fail(report, "Lantern overuse lacked observation or decision evidence")
		end
	elseif report.scenarioId == "NoteIgnorer" then
		if #report.candidateDecisions == 0 then
			ReportBuilder.fail(report, "Note ignorer did not exercise puzzle-room decision path")
		end
	elseif report.scenarioId == "PartySplit" then
		if #report.simulatedPlayers < 2 or #report.approvedDecisions == 0 then
			ReportBuilder.fail(report, "Party split lacked multiplayer approval evidence")
		end
	elseif report.scenarioId == "StaleZoneCleanup" then
		if #report.architecturalViolations > 0 then
			ReportBuilder.fail(report, "Stale zone cleanup left violations")
		end
	end

	if report.scenarioId == "ExecutionBridgeFailure" then
		if #report.failedExecutionBridgeCalls == 0 then
			ReportBuilder.fail(report, "Failed execution bridge call was not recorded")
		end

		if hasChangedCooldown(report) then
			ReportBuilder.fail(report, "Failed bridge request created cooldown state")
		end
	end

	if
		#report.rejectedDecisions > 0
		and #report.approvedDecisions == 0
		and hasChangedCooldown(report)
	then
		ReportBuilder.fail(report, "Rejected decisions changed cooldown state")
	end

	if report.scenarioId == "StaleZoneCleanup" and #report.architecturalViolations > 0 then
		ReportBuilder.fail(report, "Stale zone cleanup left violations")
	end

	if #report.diagnosticsSnapshots == 0 then
		ReportBuilder.warn(report, "No diagnostics snapshots were captured")
	end

	if not hasTraceEntries(report) and report.scenarioId ~= "IdleSilence" then
		ReportBuilder.fail(report, "No decision trace evidence was recorded")
	end

	return report
end

return SimulationValidator

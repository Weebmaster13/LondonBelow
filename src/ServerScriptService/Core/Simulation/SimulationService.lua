--!strict
--[[
	Dev-only London Engine simulation lab.

	Disabled by default. It has no remotes, does not mutate Workspace, does not
	create gameplay content, and does not create live player truth.
]]

local ServerScriptService = game:GetService("ServerScriptService")

local Core = ServerScriptService.Core
local Diagnostics = require(Core.Diagnostics)
local EventBus = require(Core.EventBus)
local Logger = require(Core.Logger)
local SnapshotManager = require(Core.SnapshotManager)

local Config = require(script.Parent.SimulationConfig)
local Registry = require(script.Parent.SimulationRegistry)
local Runner = require(script.Parent.SimulationScenarioRunner)
local SimulationDiagnostics = require(script.Parent.SimulationDiagnostics)
local Signals = require(script.Parent.SimulationSignals)
local TraceRecorder = require(script.Parent.SimulationTraceRecorder)
local Types = require(script.Parent.SimulationTypes)

local SimulationService = {}

type SimulationMode = Types.SimulationMode
type SimulationReport = Types.SimulationReport

local log = Logger.scope("SimulationService")
local initialized = false
local started = false
local mode: SimulationMode = Config.Mode :: SimulationMode
local recentReports: { SimulationReport } = {}

local function rememberReport(report: SimulationReport)
	table.insert(recentReports, report)

	while #recentReports > Config.MaxReports do
		table.remove(recentReports, 1)
	end
end

local function assertEnabled()
	if mode == "Disabled" then
		error("SimulationService is disabled", 2)
	end
end

function SimulationService.setMode(nextMode: SimulationMode)
	if nextMode ~= "Disabled" and nextMode ~= "SelfCheck" and nextMode ~= "Manual" then
		error("Invalid simulation mode: " .. tostring(nextMode), 2)
	end

	mode = nextMode
	EventBus.publishDeferred(Signals.ModeChanged, { mode = mode })
end

function SimulationService.getMode(): SimulationMode
	return mode
end

function SimulationService.runScenario(scenarioId: string): SimulationReport
	assertEnabled()

	local scenario = Registry.get(scenarioId)

	if scenario == nil then
		error("Unknown simulation scenario: " .. scenarioId, 2)
	end

	local report = Runner.run(scenario)
	rememberReport(report)
	Runner.cleanup()
	EventBus.publishDeferred(Signals.ReportBuilt, { report = report })

	return report
end

function SimulationService.runAll(): { SimulationReport }
	assertEnabled()

	local reports = {}

	for _, scenario in ipairs(Registry.getAll()) do
		table.insert(reports, SimulationService.runScenario(scenario.id))
	end

	return reports
end

function SimulationService.initialize()
	if initialized then
		return
	end

	Diagnostics.registerSampler("SimulationFramework", SimulationService.inspect)
	SnapshotManager.registerProvider("simulationFramework", SimulationService.inspect)

	local ok, err = SimulationService.validate()

	if not ok then
		error("SimulationService validation failed: " .. tostring(err), 0)
	end

	initialized = true
	log.success("SimulationService initialized")
end

function SimulationService.start()
	if started then
		return
	end

	if not initialized then
		SimulationService.initialize()
	end

	if mode == "SelfCheck" then
		local ok, result = pcall(function()
			return SimulationService.runAll()
		end)

		if not ok then
			EventBus.publishDeferred(Signals.ValidationFailed, { error = tostring(result) })
			log.warn("Simulation self-check failed: %s", tostring(result))
		end
	end

	started = true
end

function SimulationService.shutdown()
	Runner.cleanup()
	TraceRecorder.clear()
	table.clear(recentReports)
	started = false
end

function SimulationService.inspect()
	return SimulationDiagnostics.capture({
		initialized = initialized,
		started = started,
		mode = mode,
		reportCount = #recentReports,
	}, {
		SimulationRegistry = Registry,
		SimulationTraceRecorder = TraceRecorder,
		recentReports = function()
			return table.clone(recentReports)
		end,
	})
end

function SimulationService.validate(): (boolean, string?)
	return SimulationDiagnostics.validate({
		SimulationRegistry = Registry,
	})
end

return SimulationService

--!strict

local ServerScriptService = game:GetService("ServerScriptService")

local Core = ServerScriptService.Core
local Diagnostics = require(Core.Diagnostics)
local DirectorCoordinator = require(Core.Directors.DirectorCoordinator)
local DirectorRequest = require(Core.Directors.DirectorRequest)
local EventBus = require(Core.EventBus)

local EnvironmentDirector = require(ServerScriptService.Horror.Environment.EnvironmentDirector)
local EnvironmentExecutionBridge =
	require(ServerScriptService.Horror.Environment.EnvironmentExecutionBridge)
local EnvironmentMemory = require(ServerScriptService.Horror.Environment.EnvironmentMemory)
local EnvironmentState = require(ServerScriptService.Horror.Environment.EnvironmentState)
local EnvironmentZoneContext =
	require(ServerScriptService.Horror.Environment.EnvironmentZoneContext)
local ObservationRegistry = require(ServerScriptService.Horror.Observation.ObservationRegistry)
local ObservationValidator = require(ServerScriptService.Horror.Observation.ObservationValidator)

local ReportBuilder = require(script.Parent.SimulationReportBuilder)
local Signals = require(script.Parent.SimulationSignals)
local TraceRecorder = require(script.Parent.SimulationTraceRecorder)
local Validator = require(script.Parent.SimulationValidator)
local Types = require(script.Parent.SimulationTypes)

local SimulationScenarioRunner = {}

type SimulationScenario = Types.SimulationScenario
type SimulationReport = Types.SimulationReport

local function snapshot(report: SimulationReport, label: string)
	table.insert(report.diagnosticsSnapshots, {
		label = label,
		at = os.clock(),
		diagnostics = Diagnostics.capture(),
		environment = EnvironmentDirector.inspect(),
	})
end

local function countKeys(values: { [any]: any }): number
	local total = 0

	for _ in pairs(values) do
		total += 1
	end

	return total
end

local function findPlayer(scenario: SimulationScenario, userId: number?)
	if userId == nil then
		return nil
	end

	for _, profile in ipairs(scenario.players) do
		if profile.userId == userId then
			return profile
		end
	end

	return nil
end

local function injectObservation(
	scenario: SimulationScenario,
	report: SimulationReport,
	observation: Types.SimulationObservation
)
	local definition = ObservationRegistry.get(observation.id)
	local player = findPlayer(scenario, observation.playerUserId)
	local validation = ObservationValidator.validate({
		id = observation.id,
		amount = observation.amount,
		metadata = observation.metadata,
	})

	if not validation.ok or definition == nil then
		table.insert(report.observationsRejected, {
			id = observation.id,
			reason = validation.message,
			code = validation.code,
		})
		TraceRecorder.record(scenario.id, "observation rejected", observation)
		return
	end

	local syntheticObservation = {
		id = observation.id,
		kind = definition.directorKind or observation.id,
		amount = observation.amount or 1,
		playerUserId = if player ~= nil then player.userId else nil,
		metadata = table.clone(observation.metadata),
		context = {
			roomId = observation.metadata.roomId,
			areaId = observation.metadata.areaId,
			roomTags = observation.metadata.tags,
		},
	}

	table.insert(report.observationsInjected, syntheticObservation)
	TraceRecorder.record(scenario.id, "observation injected", syntheticObservation)
	EnvironmentDirector.observe(syntheticObservation)
	table.insert(report.pressureTimeline, {
		observationId = observation.id,
		score = EnvironmentDirector.inspect().state.pressureScore,
		state = EnvironmentDirector.inspect().environmentState.pressureState,
	})
end

local function requestEnvironmentDecision(
	scenario: SimulationScenario,
	report: SimulationReport,
	requestKind: string,
	preferredCategory: string?,
	zoneId: string,
	zoneKind: string,
	partySize: number
)
	local request = DirectorRequest.create({
		sourceDirector = "Simulation",
		targetDirector = "Environment",
		requestKind = requestKind,
		reason = "Simulation scenario " .. scenario.id,
		context = {
			zoneId = zoneId,
			zoneKind = zoneKind,
			partySize = partySize,
		},
		metadata = {
			preferredCategory = preferredCategory,
		},
		tags = { "simulation" },
	})

	local before = EnvironmentDirector.inspect()
	local approval = DirectorCoordinator.submitRequest(request)
	local after = EnvironmentDirector.inspect()

	table.insert(report.candidateDecisions, {
		request = request,
		approval = approval,
		lastSelection = after.lastSelection,
	})

	if approval.status == "Approved" then
		table.insert(report.approvedDecisions, approval)
	else
		table.insert(report.rejectedDecisions, {
			approval = approval,
			reason = approval.reason,
		})
	end

	table.insert(report.cooldownChanges, {
		before = before.environmentState.reactionCooldowns,
		after = after.environmentState.reactionCooldowns,
	})
	table.insert(report.memoryChanges, {
		before = before.memory,
		after = after.memory,
	})
	TraceRecorder.record(scenario.id, "environment approval", approval)
end

local function runAction(scenario: SimulationScenario, report: SimulationReport, action: string)
	local firstZone = scenario.zones[1]
	local partySize = math.max(1, #scenario.players)

	if action == "RequestReleaseSupport" then
		requestEnvironmentDecision(
			scenario,
			report,
			"RequestEnvironmentReaction",
			"ReleaseSupport",
			firstZone.zoneId,
			firstZone.zoneKind,
			partySize
		)
	elseif action == "RequestFogPressure" then
		requestEnvironmentDecision(
			scenario,
			report,
			"RequestEnvironmentReaction",
			"FogPressure",
			firstZone.zoneId,
			firstZone.zoneKind,
			partySize
		)
	elseif action == "RequestRoomPressure" then
		requestEnvironmentDecision(
			scenario,
			report,
			"RequestEnvironmentReaction",
			"RoomPressure",
			firstZone.zoneId,
			firstZone.zoneKind,
			partySize
		)
	elseif action == "RequestPuzzlePressure" then
		requestEnvironmentDecision(
			scenario,
			report,
			"RequestEnvironmentReaction",
			"DoorReaction",
			firstZone.zoneId,
			firstZone.zoneKind,
			partySize
		)
	elseif action == "InvalidBridgePayload" then
		local before = EnvironmentDirector.inspect()
		local ok, err = EnvironmentExecutionBridge.request({
			executionKind = "RequestDoorReaction",
			reactionId = "simulation.invalid",
			category = "DoorReaction",
			intensity = 0.5,
			zoneId = firstZone.zoneId,
			zoneKind = firstZone.zoneKind,
			reason = "Simulation invalid bridge payload",
			createdAt = os.clock(),
			metadata = {
				unsafe = SimulationScenarioRunner :: any,
			},
		})
		local after = EnvironmentDirector.inspect()

		if not ok then
			table.insert(report.failedExecutionBridgeCalls, {
				reason = err,
			})
		end

		if
			countKeys(after.environmentState.reactionCooldowns)
			~= countKeys(before.environmentState.reactionCooldowns)
		then
			table.insert(report.cooldownChanges, {
				before = before.environmentState.reactionCooldowns,
				after = after.environmentState.reactionCooldowns,
			})
		end
	elseif action == "StaleZoneCleanup" then
		EnvironmentState.setZonePressure(firstZone.zoneId, "Uneasy", 0.6, os.clock() - 400)
		EnvironmentState.pruneZonePressure(os.clock())

		if EnvironmentState.getZonePressure(firstZone.zoneId) ~= nil then
			table.insert(
				report.architecturalViolations,
				"Stale zone pressure remained after cleanup"
			)
		end
	end
end

function SimulationScenarioRunner.run(scenario: SimulationScenario): SimulationReport
	local report = ReportBuilder.new(scenario)
	EventBus.publishDeferred(Signals.ScenarioStarted, { scenarioId = scenario.id })
	TraceRecorder.record(scenario.id, "scenario started", { displayName = scenario.displayName })
	snapshot(report, "before")

	for _, zone in ipairs(scenario.zones) do
		EnvironmentZoneContext.registerZone(zone.zoneId, zone.zoneKind :: any, zone.tags)
	end

	for _, observation in ipairs(scenario.observations) do
		injectObservation(scenario, report, observation)
	end

	for _, action in ipairs(scenario.actions) do
		runAction(scenario, report, action)
	end

	snapshot(report, "after")
	report.decisionTraces = {
		{
			source = "Simulation",
			traces = TraceRecorder.forScenario(scenario.id),
		},
		{
			source = "DirectorCoordinator",
			traces = DirectorCoordinator.inspect().traces,
		},
	}
	report = Validator.validateReport(report)

	EventBus.publishDeferred(Signals.ScenarioCompleted, {
		scenarioId = scenario.id,
		status = report.status,
	})

	return report
end

function SimulationScenarioRunner.cleanup()
	EnvironmentState.reset()
	EnvironmentMemory.reset()
	EnvironmentZoneContext.reset()
	EnvironmentExecutionBridge.reset()
end

return SimulationScenarioRunner

--!strict
--[[
	Server bootstrap for London Engine v1.

	Bootstrap starts the Core Runtime, validates it, prints a startup summary,
	and refuses to report readiness if any required runtime system fails.
]]

local Framework = require(script.Parent.Framework)
local DirectorCoordinator = require(script.Parent.Directors.DirectorCoordinator)
local SimulationService = require(script.Parent.Simulation.SimulationService)
local AudioDirector = require(script.Parent.Parent.Horror.Audio.AudioDirector)
local DarknessService = require(script.Parent.Parent.Gameplay.Darkness.DarknessService)
local EnvironmentDirector = require(script.Parent.Parent.Horror.Environment.EnvironmentDirector)
local GameplayCoordinator = require(script.Parent.Parent.Gameplay.Core.GameplayCoordinator)
local GameplayExecutionService =
	require(script.Parent.Parent.Gameplay.Execution.GameplayExecutionService)
local HorrorDirector = require(script.Parent.Parent.Horror.Director.HorrorDirector)
local HorrorOrchestrator =
	require(script.Parent.Parent.Horror.Orchestration.Core.HorrorOrchestrator)
local LanternService = require(script.Parent.Parent.Gameplay.Lantern.LanternService)
local LightingDirector = require(script.Parent.Parent.Horror.Lighting.LightingDirector)
local LivingCognitionCoordinator =
	require(script.Parent.Parent.AI.LivingCognition.Core.LivingCognitionCoordinator)
local MonsterIntelligenceCoordinator =
	require(script.Parent.Parent.AI.MonsterIntelligence.Core.MonsterIntelligenceCoordinator)
local ObservationService = require(script.Parent.Parent.Horror.Observation.ObservationService)
local PlayerService = require(script.Parent.Parent.Player.PlayerService)
local PlayerExperienceService = require(script.Parent.Parent.Gameplay.PlayerExperienceService)
local LobbyService = require(script.Parent.Parent.Lobby.LobbyService)
local PortalService = require(script.Parent.Parent.Lobby.Portals.PortalService)
local PortalZoneBinder = require(script.Parent.Parent.Lobby.Portals.PortalZoneBinder)
local Logger = require(script.Parent.Logger)

local log = Logger.scope("Bootstrap")

local function startEngine()
	log.info("Starting London Engine")

	Framework.registerModule("LobbyService", LobbyService, {
		"Logger",
		"EventBus",
		"RemoteManager",
		"Scheduler",
		"Diagnostics",
		"SnapshotManager",
	})

	Framework.registerModule("PortalService", PortalService, {
		"Logger",
		"EventBus",
		"RemoteManager",
		"Scheduler",
		"Diagnostics",
		"SnapshotManager",
		"LobbyService",
	})

	Framework.registerModule("PortalZoneBinder", PortalZoneBinder, {
		"Logger",
		"PortalService",
	})

	Framework.registerModule("ObservationService", ObservationService, {
		"Logger",
		"EventBus",
		"Scheduler",
		"Diagnostics",
		"SnapshotManager",
	})

	Framework.registerModule("HorrorDirector", HorrorDirector, {
		"Logger",
		"EventBus",
		"Scheduler",
		"Diagnostics",
		"SnapshotManager",
		"ObservationService",
	})

	Framework.registerModule("DirectorCoordinator", DirectorCoordinator, {
		"Logger",
		"EventBus",
		"Scheduler",
		"Diagnostics",
		"SnapshotManager",
		"ObservationService",
	})

	Framework.registerModule("EnvironmentDirector", EnvironmentDirector, {
		"Logger",
		"EventBus",
		"Scheduler",
		"Diagnostics",
		"SnapshotManager",
		"ObservationService",
		"DirectorCoordinator",
	})

	Framework.registerModule("LightingDirector", LightingDirector, {
		"Logger",
		"EventBus",
		"Scheduler",
		"Diagnostics",
		"SnapshotManager",
		"DirectorCoordinator",
		"EnvironmentDirector",
	})

	Framework.registerModule("AudioDirector", AudioDirector, {
		"Logger",
		"EventBus",
		"Scheduler",
		"Diagnostics",
		"SnapshotManager",
		"DirectorCoordinator",
		"EnvironmentDirector",
	})

	Framework.registerModule("PlayerService", PlayerService, {
		"Logger",
		"EventBus",
		"Diagnostics",
		"SnapshotManager",
	})

	Framework.registerModule("PlayerExperienceService", PlayerExperienceService, {
		"Logger",
		"EventBus",
		"RemoteManager",
		"Diagnostics",
		"SnapshotManager",
		"ObservationService",
		"PlayerService",
	})

	Framework.registerModule("LanternService", LanternService, {
		"Logger",
		"EventBus",
		"RemoteManager",
		"Diagnostics",
		"SnapshotManager",
		"ObservationService",
		"DirectorCoordinator",
		"LightingDirector",
		"AudioDirector",
	})

	Framework.registerModule("DarknessService", DarknessService, {
		"Logger",
		"EventBus",
		"Scheduler",
		"Diagnostics",
		"SnapshotManager",
		"ObservationService",
		"DirectorCoordinator",
		"LightingDirector",
		"AudioDirector",
		"EnvironmentDirector",
	})

	Framework.registerModule("GameplayCoordinator", GameplayCoordinator, {
		"Logger",
		"EventBus",
		"Diagnostics",
		"SnapshotManager",
		"ObservationService",
		"DirectorCoordinator",
	})

	Framework.registerModule("GameplayExecutionService", GameplayExecutionService, {
		"Logger",
		"EventBus",
		"Scheduler",
		"Diagnostics",
		"SnapshotManager",
		"GameplayCoordinator",
	})

	Framework.registerModule("MonsterIntelligenceCoordinator", MonsterIntelligenceCoordinator, {
		"Logger",
		"EventBus",
		"Scheduler",
		"Diagnostics",
		"SnapshotManager",
		"ObservationService",
		"DirectorCoordinator",
		"GameplayExecutionService",
	})

	Framework.registerModule("LivingCognitionCoordinator", LivingCognitionCoordinator, {
		"Logger",
		"EventBus",
		"Scheduler",
		"Diagnostics",
		"SnapshotManager",
		"ObservationService",
		"MonsterIntelligenceCoordinator",
		"HorrorOrchestrator",
	})

	Framework.registerModule("HorrorOrchestrator", HorrorOrchestrator, {
		"Logger",
		"EventBus",
		"Scheduler",
		"Diagnostics",
		"SnapshotManager",
		"ObservationService",
		"DirectorCoordinator",
		"HorrorDirector",
		"EnvironmentDirector",
		"LightingDirector",
		"AudioDirector",
		"MonsterIntelligenceCoordinator",
		"GameplayCoordinator",
		"GameplayExecutionService",
	})

	Framework.registerModule("SimulationService", SimulationService, {
		"Logger",
		"EventBus",
		"Diagnostics",
		"SnapshotManager",
		"ObservationService",
		"DirectorCoordinator",
		"EnvironmentDirector",
		"PlayerService",
		"PlayerExperienceService",
	})

	local initialized = Framework.initialize({
		mode = "Development",
		debug = true,
	})

	if not initialized then
		error("London Engine initialization failed", 0)
	end

	local started = Framework.start()

	if not started then
		error("London Engine startup failed", 0)
	end

	local valid, validationErr = Framework.validate()

	if not valid then
		error("London Engine validation failed: " .. tostring(validationErr), 0)
	end

	local health = Framework.printStartupSummary()

	if not health.healthy then
		error("London Engine health check failed", 0)
	end

	log.success("London Engine is ready")
end

local ok, err = pcall(startEngine)

if not ok then
	log.fatal("Bootstrap refused startup: %s", tostring(err))
	error(err, 0)
end

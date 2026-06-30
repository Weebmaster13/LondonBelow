--!strict
--[[
	Server-authoritative Darkness runtime.

	Trusted server systems call enterDarkness, exitDarkness, or updateExposure.
	Clients do not own darkness truth. This service emits observations and asks
	Directors for future sensory/environment pressure without mutating Workspace,
	Roblox Lighting, audio, final UI, final art, or Monster AI.
]]

local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")

local Core = ServerScriptService.Core
local Diagnostics = require(Core.Diagnostics)
local DirectorCoordinator = require(Core.Directors.DirectorCoordinator)
local DirectorRequest = require(Core.Directors.DirectorRequest)
local EventBus = require(Core.EventBus)
local Logger = require(Core.Logger)
local Scheduler = require(Core.Scheduler)
local SnapshotManager = require(Core.SnapshotManager)

local ObservationService = require(ServerScriptService.Horror.Observation.ObservationService)
local WorldZoneContext = require(ServerScriptService.World.WorldZoneContext)

local Config = require(script.Parent.DarknessConfig)
local DarknessDiagnostics = require(script.Parent.DarknessDiagnostics)
local DarknessExposureTracker = require(script.Parent.DarknessExposureTracker)
local DarknessSignals = require(script.Parent.DarknessSignals)
local Types = require(script.Parent.DarknessTypes)

local DarknessService = {}

type DarknessContext = Types.DarknessContext

local log = Logger.scope("DarknessService")
local initialized = false
local started = false
local eventConnections: { RBXScriptConnection } = {}
local updateHandle: Scheduler.TaskHandle? = nil

local function now(): number
	return os.clock()
end

local function worldContextFor(context: DarknessContext?)
	return WorldZoneContext.fromPayload({
		context = {
			zoneId = if context ~= nil then context.zoneId else nil,
			zoneKind = if context ~= nil then context.zoneKind else nil,
		},
		metadata = if context ~= nil and context.metadata ~= nil then context.metadata else {},
	})
end

local function isProtected(worldContext: any): boolean
	return worldContext.zoneKind == "SafeRoom"
		or worldContext.puzzleProtection.protectsActivePuzzle == true
		or worldContext.isKnown == false
end

local function observe(player: Player, id: string, state: any, extra: { [string]: any }?)
	local metadata = {
		roomId = state.zoneId,
		zoneId = state.zoneId,
		zoneKind = state.zoneKind,
		exposure = state.exposure,
		protected = state.protected,
	}

	if extra ~= nil then
		for key, value in pairs(extra) do
			metadata[key] = value
		end
	end

	local ok, code = ObservationService.observe({
		id = id,
		player = player,
		source = "DarknessService",
		amount = state.exposure,
		metadata = metadata,
	})

	if not ok then
		log.withContext("WARN", "Darkness observation rejected", {
			observationId = id,
			userId = player.UserId,
			code = code,
		})
	end
end

local function requestDirectors(player: Player, state: any, reason: string)
	if state.protected or state.exposure < Config.DirectorRequestThreshold then
		return
	end

	local context = {
		playerUserId = player.UserId,
		zoneId = state.zoneId,
		zoneKind = state.zoneKind,
		partySize = 1,
	}

	DarknessExposureTracker.recordDirectorRequest()
	DirectorCoordinator.submitRequest(DirectorRequest.create({
		sourceDirector = "DarknessService",
		targetDirector = "Lighting",
		requestKind = "RequestLightingChange",
		reason = reason,
		context = context,
		metadata = {
			lightingKind = "VisibilityPressure",
		},
		tags = { "darkness", "presentation-hook" },
	}))

	DirectorCoordinator.submitRequest(DirectorRequest.create({
		sourceDirector = "DarknessService",
		targetDirector = "Audio",
		requestKind = "RequestHeartbeatPressure",
		reason = "Darkness exposure may justify future heartbeat pressure.",
		context = context,
		metadata = {
			audioKind = "HeartbeatPressure",
		},
		tags = { "darkness", "presentation-hook" },
	}))

	DirectorCoordinator.submitRequest(DirectorRequest.create({
		sourceDirector = "DarknessService",
		targetDirector = "Environment",
		requestKind = "RequestEnvironmentReaction",
		reason = "Darkness exposure may justify future environment pressure.",
		context = context,
		metadata = {
			preferredCategory = "RoomPressure",
		},
		tags = { "darkness", "presentation-hook" },
	}))
end

function DarknessService.enterDarkness(player: Player, context: DarknessContext?)
	local worldContext = worldContextFor(context)
	local protected = isProtected(worldContext)
	local state =
		DarknessExposureTracker.enter(player, worldContext.zoneId, worldContext.zoneKind, protected)

	if protected then
		observe(player, "Darkness.ProtectedZone", state, nil)
		EventBus.publishDeferred(DarknessSignals.ProtectedZone, { player = player, state = state })
	else
		observe(player, "Darkness.Entered", state, nil)
		EventBus.publishDeferred(DarknessSignals.Entered, { player = player, state = state })
	end

	return state
end

function DarknessService.exitDarkness(player: Player)
	local state = DarknessExposureTracker.exit(player)
	observe(player, "Darkness.Exited", state, nil)
	EventBus.publishDeferred(DarknessSignals.Exited, { player = player, state = state })
	return state
end

function DarknessService.updateExposure(player: Player, context: DarknessContext?)
	local intensity = if context ~= nil and type(context.intensity) == "number"
		then math.clamp(context.intensity, 0, 1)
		else 1
	local state = DarknessExposureTracker.update(player, intensity, now())

	if state.inDarkness and not state.protected then
		observe(player, "Darkness.ExposureIncreased", state, { intensity = intensity })
		EventBus.publishDeferred(
			DarknessSignals.ExposureIncreased,
			{ player = player, state = state }
		)
		requestDirectors(player, state, "Darkness exposure increased future sensory pressure.")
	end

	return state
end

local function updateAll()
	for _, player in ipairs(Players:GetPlayers()) do
		DarknessService.updateExposure(player, nil)
	end
end

function DarknessService.handlePlayerRemoving(player: Player)
	DarknessExposureTracker.remove(player)
end

function DarknessService.initialize()
	if initialized then
		return
	end

	Diagnostics.registerSampler("DarknessService", DarknessService.inspect)
	SnapshotManager.registerProvider("darknessService", DarknessService.inspect)

	local valid, validationErr = DarknessService.validate()
	if not valid then
		error("DarknessService validation failed: " .. tostring(validationErr), 0)
	end

	initialized = true
	log.success("DarknessService initialized")
end

function DarknessService.start()
	if started then
		return
	end

	if not initialized then
		DarknessService.initialize()
	end

	for _, player in ipairs(Players:GetPlayers()) do
		DarknessExposureTracker.ensure(player)
	end

	table.insert(
		eventConnections,
		Players.PlayerAdded:Connect(function(player)
			DarknessExposureTracker.ensure(player)
		end)
	)
	table.insert(
		eventConnections,
		Players.PlayerRemoving:Connect(DarknessService.handlePlayerRemoving)
	)
	updateHandle = Scheduler.interval(
		Config.UpdateIntervalSeconds,
		updateAll,
		"DarknessExposureUpdate",
		"DarknessService",
		{ "Gameplay", "Darkness" }
	)
	started = true
	log.success("DarknessService started")
end

function DarknessService.shutdown()
	if updateHandle ~= nil then
		Scheduler.cancel(updateHandle)
		updateHandle = nil
	end

	for _, connection in ipairs(eventConnections) do
		connection:Disconnect()
	end

	table.clear(eventConnections)
	DarknessExposureTracker.clear()
	started = false
	initialized = false
end

function DarknessService.inspect()
	return DarknessDiagnostics.capture({
		initialized = initialized,
		started = started,
	}, {
		DarknessExposureTracker = DarknessExposureTracker,
	})
end

function DarknessService.validate(): (boolean, string?)
	return DarknessDiagnostics.validate()
end

function DarknessService.runSelfChecks()
	local valid, validationErr = DarknessService.validate()
	local unknown = WorldZoneContext.fromPayload({})

	return {
		ok = valid
			and unknown.isKnown == false
			and unknown.lightingPolicy.allowsBlackout == false
			and unknown.puzzleProtection.allowsMajorInterruptions == false,
		error = validationErr,
		serverAuthoritative = true,
		unknownZonesConservative = true,
	}
end

return DarknessService

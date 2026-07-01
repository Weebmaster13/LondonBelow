--!strict
--[[
	Server-authoritative Lantern runtime.

	Clients may request lantern on/off only. The server owns equipped state,
	on/off truth, battery/fuel hooks, overuse tracking, observations, Director
	requests, diagnostics, snapshots, and presentation-hook remotes.

	This service does not create final lighting effects, final UI, final audio,
	Chapter 1 content, Monster AI, or client-owned fear/darkness truth.
]]

local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")

local Core = ServerScriptService.Core
local Diagnostics = require(Core.Diagnostics)
local DirectorCoordinator = require(Core.Directors.DirectorCoordinator)
local DirectorRequest = require(Core.Directors.DirectorRequest)
local EventBus = require(Core.EventBus)
local Logger = require(Core.Logger)
local RemoteManager = require(Core.RemoteManager)
local SnapshotManager = require(Core.SnapshotManager)

local ObservationService = require(ServerScriptService.Horror.Observation.ObservationService)
local WorldZoneContext = require(ServerScriptService.World.WorldZoneContext)

local Config = require(script.Parent.LanternConfig)
local LanternDiagnostics = require(script.Parent.LanternDiagnostics)
local LanternSignals = require(script.Parent.LanternSignals)
local LanternState = require(script.Parent.LanternState)
local LanternValidator = require(script.Parent.LanternValidator)
local Types = require(script.Parent.LanternTypes)

local LanternService = {}

type LanternResult = Types.LanternResult
type ToggleRequest = Types.ToggleRequest

local log = Logger.scope("LanternService")
local initialized = false
local started = false
local eventConnections: { RBXScriptConnection } = {}
local remotes: { [string]: RemoteEvent } = {}

local function now(): number
	return os.clock()
end

local function defineRemote(name: string, rateLimit: number?): RemoteEvent
	local remote = RemoteManager.define({
		namespace = Config.RemoteNamespace,
		name = name,
		version = Config.RemoteVersion,
		kind = "Event",
		rateLimit = rateLimit,
	}) :: RemoteEvent

	remotes[name] = remote
	return remote
end

local function getRemote(name: string): RemoteEvent
	local remote = remotes[name]
	if remote == nil then
		error("Lantern remote not initialized: " .. name, 2)
	end

	return remote
end

local function result(ok: boolean, code: string, message: string, status: any?): LanternResult
	return {
		ok = ok,
		code = code,
		message = message,
		status = status,
	}
end

local function observe(player: Player, id: string, status: any, extra: { [string]: any }?)
	local metadata = {
		roomId = status.zoneId,
		zoneId = status.zoneId,
		zoneKind = status.zoneKind,
		battery = status.battery,
		overuseScore = status.overuseScore,
		protected = status.protected,
	}

	if extra ~= nil then
		for key, value in pairs(extra) do
			metadata[key] = value
		end
	end

	local ok, code = ObservationService.observe({
		id = id,
		player = player,
		source = "LanternService",
		amount = if type(extra) == "table" and type(extra.amount) == "number"
			then extra.amount
			else 1,
		metadata = metadata,
	})

	if not ok then
		log.withContext("WARN", "Lantern observation rejected", {
			observationId = id,
			userId = player.UserId,
			code = code,
		})
	end
end

local function requestSensoryDirectors(player: Player, status: any, reason: string)
	if status.protected then
		LanternState.recordDirectorRequestSuppressed()
		return
	end

	local currentTime = now()

	if currentTime - status.lastDirectorRequestAt < Config.DirectorRequestCooldownSeconds then
		LanternState.recordDirectorRequestSuppressed()
		return
	end

	LanternState.patch(player, {
		lastDirectorRequestAt = currentTime,
	})
	LanternState.recordDirectorRequest()

	local context = {
		playerUserId = player.UserId,
		zoneId = status.zoneId,
		zoneKind = status.zoneKind,
		partySize = 1,
	}

	DirectorCoordinator.submitRequest(DirectorRequest.create({
		sourceDirector = "LanternService",
		targetDirector = "Lighting",
		requestKind = "RequestLightingChange",
		reason = reason,
		context = context,
		metadata = {
			lightingKind = if status.on then "ReleaseLighting" else "Dim",
		},
		tags = { "lantern", "presentation-hook" },
	}))

	if status.overuseScore >= Config.OveruseThreshold then
		DirectorCoordinator.submitRequest(DirectorRequest.create({
			sourceDirector = "LanternService",
			targetDirector = "Audio",
			requestKind = "RequestAudioCue",
			reason = "Lantern overuse may justify future subtle audio pressure.",
			context = context,
			metadata = {
				audioKind = "BreathingPressure",
			},
			tags = { "lantern", "overuse", "presentation-hook" },
		}))
	end
end

local function worldContextFor(status: any)
	return WorldZoneContext.fromPayload({
		context = {
			zoneId = status.zoneId,
			zoneKind = status.zoneKind,
		},
		metadata = {},
	})
end

local function sendState(player: Player, status: any)
	getRemote(Config.ServerToClient.StateUpdated):FireClient(player, {
		status = status,
		presentationOnly = true,
	})
end

function LanternService.equip(player: Player, zoneId: string?, zoneKind: string?)
	local worldContext = WorldZoneContext.fromPayload({
		context = {
			zoneId = zoneId,
			zoneKind = zoneKind,
		},
	})
	local status = LanternState.patch(player, {
		equipped = true,
		zoneId = worldContext.zoneId,
		zoneKind = worldContext.zoneKind,
		protected = worldContext.isKnown == false
			or worldContext.zoneKind == "SafeRoom"
			or worldContext.puzzleProtection.protectsActivePuzzle == true,
	})
	LanternState.incrementCounter("equipped")
	observe(player, "Lantern.Equipped", status, nil)
	EventBus.publishDeferred(LanternSignals.StateChanged, { player = player, status = status })
	return status
end

function LanternService.unequip(player: Player, zoneId: string?, zoneKind: string?)
	local worldContext = WorldZoneContext.fromPayload({
		context = {
			zoneId = zoneId,
			zoneKind = zoneKind,
		},
	})
	local status = LanternState.patch(player, {
		equipped = false,
		on = false,
		zoneId = worldContext.zoneId,
		zoneKind = worldContext.zoneKind,
		protected = true,
	})
	LanternState.incrementCounter("unequipped")
	observe(player, "Lantern.Unequipped", status, nil)
	EventBus.publishDeferred(LanternSignals.StateChanged, { player = player, status = status })
	return status
end

function LanternService.requestToggle(player: Player, payload: any): LanternResult
	local request = LanternValidator.sanitizeToggle(payload)

	if request == nil or request.equipped ~= nil then
		LanternState.recordRejected()
		return result(
			false,
			Types.ResultCode.InvalidRequest,
			"Lantern toggle request is malformed.",
			nil
		)
	end

	if LanternState.isReplay(player, request.requestId) then
		LanternState.recordReplay()
		LanternState.recordRejected()
		return result(
			false,
			Types.ResultCode.InvalidRequest,
			"Lantern toggle request was replayed.",
			LanternState.get(player)
		)
	end

	local status = LanternState.ensure(player)
	local currentTime = now()
	local canToggle, code = LanternValidator.canToggle(status, currentTime)

	if not canToggle then
		LanternState.recordRejected()
		return result(false, code, "Lantern toggle request was rejected.", status)
	end

	if not status.equipped then
		LanternState.recordRejected()
		LanternState.rememberRequest(player, request.requestId)
		return result(false, Types.ResultCode.NotEquipped, "Lantern is not equipped.", status)
	end

	LanternState.rememberRequest(player, request.requestId)
	local worldContext = worldContextFor(status)
	local nextOn = if request.on ~= nil then request.on else not status.on
	local nextBattery = math.max(0, status.battery - Config.BatteryDrainPerToggle)
	local nextOveruse = math.clamp(status.overuseScore + Config.OveruseIncrement, 0, 1)
	local protected = worldContext.isKnown == false
		or worldContext.zoneKind == "SafeRoom"
		or worldContext.puzzleProtection.protectsActivePuzzle == true

	local nextStatus = LanternState.patch(player, {
		on = nextOn,
		battery = nextBattery,
		overuseScore = nextOveruse,
		lastToggleAt = currentTime,
		zoneId = worldContext.zoneId,
		zoneKind = worldContext.zoneKind,
		protected = protected,
	})

	if nextOn then
		LanternState.incrementCounter("turnedOn")
		observe(player, "Lantern.TurnedOn", nextStatus, nil)
	else
		LanternState.incrementCounter("turnedOff")
		observe(player, "Lantern.TurnedOff", nextStatus, nil)
	end

	if
		nextBattery <= Config.LowBatteryThreshold
		and currentTime - status.lastLowBatteryAt >= Config.LowBatteryObservationCooldownSeconds
	then
		nextStatus = LanternState.patch(player, {
			lastLowBatteryAt = currentTime,
		})
		LanternState.incrementCounter("lowBattery")
		observe(player, "Lantern.LowBattery", nextStatus, { level = nextBattery })
		EventBus.publishDeferred(
			LanternSignals.LowBattery,
			{ player = player, status = nextStatus }
		)
	elseif nextBattery <= Config.LowBatteryThreshold then
		LanternState.incrementCounter("lowBatterySuppressed")
	end

	if
		nextOveruse >= Config.OveruseThreshold
		and currentTime - status.lastOveruseAt >= Config.OveruseObservationCooldownSeconds
	then
		nextStatus = LanternState.patch(player, {
			lastOveruseAt = currentTime,
		})
		LanternState.incrementCounter("overused")
		observe(player, "Lantern.Overused", nextStatus, { amount = nextOveruse })
		EventBus.publishDeferred(LanternSignals.Overused, { player = player, status = nextStatus })
	elseif nextOveruse >= Config.OveruseThreshold then
		LanternState.incrementCounter("overuseSuppressed")
	end

	requestSensoryDirectors(
		player,
		nextStatus,
		"Lantern toggle created future presentation pressure."
	)
	EventBus.publishDeferred(LanternSignals.Toggled, { player = player, status = nextStatus })
	sendState(player, nextStatus)

	return result(true, Types.ResultCode.Ok, "Lantern state updated.", nextStatus)
end

function LanternService.handlePlayerRemoving(player: Player)
	LanternState.remove(player)
end

function LanternService.initialize()
	if initialized then
		return
	end

	defineRemote(Config.ClientToServer.RequestToggle, Config.RemoteRateLimitPerSecond)
	defineRemote(Config.ServerToClient.StateUpdated, nil)
	defineRemote(Config.ServerToClient.RequestResult, nil)

	local toggleRemote = getRemote(Config.ClientToServer.RequestToggle)
	table.insert(
		eventConnections,
		toggleRemote.OnServerEvent:Connect(function(player, payload)
			local ok, reason = RemoteManager.validateCall(
				player,
				Config.RemoteNamespace,
				Config.ClientToServer.RequestToggle,
				Config.RemoteVersion,
				payload
			)

			if not ok then
				getRemote(Config.ServerToClient.RequestResult):FireClient(
					player,
					result(
						false,
						Types.ResultCode.InvalidRequest,
						reason or "Lantern request rejected.",
						nil
					)
				)
				return
			end

			getRemote(Config.ServerToClient.RequestResult):FireClient(
				player,
				LanternService.requestToggle(player, payload)
			)
		end)
	)

	Diagnostics.registerSampler("LanternService", LanternService.inspect)
	SnapshotManager.registerProvider("lanternService", LanternService.inspect)

	local valid, validationErr = LanternService.validate()
	if not valid then
		error("LanternService validation failed: " .. tostring(validationErr), 0)
	end

	initialized = true
	log.success("LanternService initialized")
end

function LanternService.start()
	if started then
		return
	end

	for _, player in ipairs(Players:GetPlayers()) do
		LanternState.ensure(player)
	end

	table.insert(
		eventConnections,
		Players.PlayerAdded:Connect(function(player)
			LanternState.ensure(player)
		end)
	)
	table.insert(
		eventConnections,
		Players.PlayerRemoving:Connect(LanternService.handlePlayerRemoving)
	)
	started = true
end

function LanternService.shutdown()
	for _, connection in ipairs(eventConnections) do
		connection:Disconnect()
	end

	table.clear(eventConnections)
	LanternState.clear()
	started = false
	initialized = false
end

function LanternService.inspect()
	return LanternDiagnostics.capture({
		initialized = initialized,
		started = started,
		playersTracked = #Players:GetPlayers(),
	}, {
		LanternState = LanternState,
	})
end

function LanternService.validate(): (boolean, string?)
	return LanternDiagnostics.validate({
		LanternValidator = LanternValidator,
	})
end

function LanternService.runSelfChecks()
	local valid, validationErr = LanternService.validate()
	local fakePlayer = {
		UserId = -12012,
	} :: any
	local malformed = LanternService.requestToggle(fakePlayer, {})
	local notEquipped = LanternService.requestToggle(fakePlayer, {
		requestId = "lantern-self-check-replay",
		on = true,
	})
	local replayed = LanternService.requestToggle(fakePlayer, {
		requestId = "lantern-self-check-replay",
		on = true,
	})
	LanternState.remove(fakePlayer)

	return {
		ok = valid
			and malformed.ok == false
			and notEquipped.code == Types.ResultCode.NotEquipped
			and replayed.ok == false,
		error = validationErr,
		malformed = malformed.code,
		notEquipped = notEquipped.code,
		replayed = replayed.code,
		remoteNamespace = Config.RemoteNamespace,
		serverAuthoritative = true,
		workspaceMutation = false,
	}
end

return LanternService

--!strict
--[[
	PlayerService is the authoritative London Engine Player Runtime.

	Owns player lifecycle state, movement state hooks, room/area/chapter hooks,
	lock state, diagnostics, snapshots, and future stamina/fear/injury extension
	points. It does not own client camera, final UI, final audio, Monster AI, or
	chapter content.
]]

local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")

local Core = ServerScriptService.Core
local Diagnostics = require(Core.Diagnostics)
local EventBus = require(Core.EventBus)
local Logger = require(Core.Logger)
local SnapshotManager = require(Core.SnapshotManager)

local ObservationService = require(ServerScriptService.Horror.Observation.ObservationService)
local PlayerControllerService = require(ServerScriptService.Gameplay.Player.PlayerControllerService)
local PlayerDiagnostics = require(script.Parent.PlayerDiagnostics)
local PlayerStateService = require(script.Parent.PlayerStateService)
local PlayerTypes = require(script.Parent.PlayerTypes)

local PlayerService = {}

type PlayerStatePatch = PlayerTypes.PlayerStatePatch

local log = Logger.scope("PlayerService")
local initialized = false
local started = false
local eventConnections: { RBXScriptConnection } = {}

local function observeLocation(
	player: Player,
	id: string,
	roomId: string?,
	areaId: string?,
	chapterId: string?
)
	local ok, code = ObservationService.observe({
		id = id,
		player = player,
		source = "PlayerService",
		metadata = {
			roomId = roomId,
			areaId = areaId,
			chapterId = chapterId,
		},
	})

	if not ok then
		log.withContext("WARN", "Player location observation rejected", {
			observationId = id,
			userId = player.UserId,
			code = code,
		})
	end
end

function PlayerService.patchState(player: Player, patch: PlayerStatePatch)
	local state = PlayerStateService.patch(player, patch)

	EventBus.publishDeferred("Player.StateChanged", {
		player = player,
		state = state,
	})

	return state
end

function PlayerService.getState(player: Player)
	return PlayerStateService.ensure(player)
end

function PlayerService.setInteractionLocked(player: Player, locked: boolean)
	return PlayerService.patchState(player, {
		interactionLocked = locked,
	})
end

function PlayerService.setCinematicLocked(player: Player, locked: boolean)
	return PlayerService.patchState(player, {
		cinematicLocked = locked,
	})
end

function PlayerService.updateLocation(
	player: Player,
	roomId: string?,
	areaId: string?,
	chapterId: string?
)
	local previous = PlayerStateService.ensure(player)
	local state = PlayerService.patchState(player, {
		currentRoomId = roomId,
		currentAreaId = areaId,
		currentChapterId = chapterId,
	})

	if previous.currentRoomId ~= nil and roomId ~= nil and previous.currentRoomId ~= roomId then
		observeLocation(
			player,
			"Exploration.ExitRoom",
			previous.currentRoomId,
			previous.currentAreaId,
			previous.currentChapterId
		)
		observeLocation(player, "Exploration.EnterRoom", roomId, areaId, chapterId)

		EventBus.publishDeferred("Player.RoomChanged", {
			player = player,
			previousRoomId = previous.currentRoomId,
			roomId = roomId,
		})
	elseif previous.currentRoomId == nil and roomId ~= nil then
		observeLocation(player, "Exploration.EnterRoom", roomId, areaId, chapterId)
	elseif previous.currentRoomId ~= nil and roomId == nil then
		observeLocation(
			player,
			"Exploration.ExitRoom",
			previous.currentRoomId,
			previous.currentAreaId,
			previous.currentChapterId
		)
	end

	return state
end

function PlayerService.initialize()
	if initialized then
		return
	end

	Diagnostics.registerSampler("PlayerRuntime", PlayerService.inspect)
	SnapshotManager.registerProvider("playerRuntime", PlayerService.inspect)

	local ok, err = PlayerService.validate()

	if not ok then
		error("PlayerService validation failed: " .. tostring(err), 0)
	end

	initialized = true
	log.success("PlayerService initialized")
end

function PlayerService.start()
	if started then
		return
	end

	for _, player in ipairs(Players:GetPlayers()) do
		PlayerStateService.ensure(player)
	end

	table.insert(
		eventConnections,
		Players.PlayerAdded:Connect(function(player)
			PlayerStateService.ensure(player)
		end)
	)

	table.insert(
		eventConnections,
		Players.PlayerRemoving:Connect(function(player)
			PlayerStateService.remove(player)
		end)
	)

	started = true
	log.success("PlayerService started")
end

function PlayerService.shutdown()
	for _, connection in ipairs(eventConnections) do
		connection:Disconnect()
	end

	table.clear(eventConnections)
	PlayerStateService.clear()
	started = false
end

function PlayerService.inspect()
	return PlayerDiagnostics.capture({
		initialized = initialized,
		started = started,
	}, {
		PlayerStateService = PlayerStateService,
		PlayerControllerService = PlayerControllerService,
	})
end

function PlayerService.validate(): (boolean, string?)
	return PlayerDiagnostics.validate({
		PlayerStateService = PlayerStateService,
		PlayerControllerService = PlayerControllerService,
	})
end

return PlayerService

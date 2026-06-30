--!strict
--[[
	PlayerExperienceService is the Phase 6 server boundary.

	Owns RemoteManager definitions, lifecycle, diagnostics, snapshots, player
	joins/leaves, movement profile replication, and authoritative routing for
	movement and interaction requests.

	It does not implement Chapter 1, Monster AI, final UI/art, puzzle answers,
	inventory truth, or horror pacing.
]]

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Core = ServerScriptService.Core
local Diagnostics = require(Core.Diagnostics)
local EventBus = require(Core.EventBus)
local Logger = require(Core.Logger)
local RemoteManager = require(Core.RemoteManager)
local SnapshotManager = require(Core.SnapshotManager)

local InteractionRegistry = require(script.Parent.Interaction.InteractionRegistry)
local InteractionService = require(script.Parent.Interaction.InteractionService)
local FeedbackService = require(script.Parent.Interaction.FeedbackService)
local PlayerControllerService = require(script.Parent.Player.PlayerControllerService)

local PlayerExperienceConfig = require(ReplicatedStorage.Config.PlayerExperienceConfig)
local RemoteNames = require(ReplicatedStorage.Shared.PlayerExperienceRemoteNames)
local Types = require(ReplicatedStorage.Shared.PlayerExperienceTypes)

local PlayerExperienceService = {}

type InteractionDescriptor = Types.InteractionDescriptor
type FeedbackInstruction = Types.FeedbackInstruction

local log = Logger.scope("PlayerExperienceService")
local initialized = false
local started = false
local remoteEvents: { [string]: RemoteEvent } = {}
local eventConnections: { RBXScriptConnection } = {}
local busDisconnects: { () -> () } = {}
local characterConnectionsByUserId: { [number]: RBXScriptConnection } = {}

local function defineRemote(name: string, rateLimit: number?): RemoteEvent
	local remote = RemoteManager.define({
		namespace = RemoteNames.Namespace,
		name = name,
		version = RemoteNames.Version,
		kind = "Event",
		rateLimit = rateLimit,
	}) :: RemoteEvent

	remoteEvents[name] = remote
	return remote
end

local function getRemote(name: string): RemoteEvent
	local remote = remoteEvents[name]

	if remote == nil then
		error("PlayerExperience remote not initialized: " .. name, 2)
	end

	return remote
end

local function validateRemote(player: Player, name: string, ...: any): boolean
	local ok, reason =
		RemoteManager.validateCall(player, RemoteNames.Namespace, name, RemoteNames.Version, ...)

	if not ok then
		getRemote(RemoteNames.ServerToClient.InteractionResult):FireClient(player, {
			ok = false,
			code = Types.ResultCode.InvalidRequest,
			message = reason or "Request rejected.",
			interaction = nil,
			feedback = {},
		})

		return false
	end

	return true
end

local function serializeFocus(descriptor: InteractionDescriptor?)
	if descriptor == nil then
		return {
			interactionId = nil,
			prompt = nil,
			kind = nil,
			priority = nil,
			maxDistance = nil,
			metadata = nil,
		}
	end

	return {
		interactionId = descriptor.id,
		prompt = descriptor.prompt,
		kind = descriptor.kind,
		priority = descriptor.priority,
		maxDistance = descriptor.maxDistance,
		metadata = descriptor.metadata,
	}
end

local function registerRemotes()
	for _, name in pairs(RemoteNames.ClientToServer) do
		defineRemote(name, PlayerExperienceConfig.RemoteRateLimitPerSecond)
	end

	for _, name in pairs(RemoteNames.ServerToClient) do
		defineRemote(name, nil)
	end
end

local function connectClientRemote(name: string, callback: (Player, any) -> ())
	local remote = getRemote(name)
	local connection = remote.OnServerEvent:Connect(function(player: Player, payload: any)
		if not validateRemote(player, name, payload) then
			return
		end

		local ok, err = pcall(callback, player, payload)

		if not ok then
			log.withContext("ERROR", "PlayerExperience remote handler failed", {
				remote = name,
				userId = player.UserId,
				error = tostring(err),
			})
			getRemote(RemoteNames.ServerToClient.InteractionResult):FireClient(player, {
				ok = false,
				code = Types.ResultCode.ServerError,
				message = "Player experience request failed.",
				interaction = nil,
				feedback = {},
			})
		end
	end)

	table.insert(eventConnections, connection)
end

local function connectRemotes()
	connectClientRemote(RemoteNames.ClientToServer.RequestInteraction, function(player, payload)
		local interactionResult = InteractionService.requestInteraction(player, payload)
		getRemote(RemoteNames.ServerToClient.InteractionResult):FireClient(
			player,
			interactionResult
		)
	end)

	connectClientRemote(RemoteNames.ClientToServer.RequestFocus, function(player, payload)
		local descriptor = InteractionService.requestFocus(player, payload)
		getRemote(RemoteNames.ServerToClient.FocusUpdated):FireClient(
			player,
			serializeFocus(descriptor)
		)
	end)

	connectClientRemote(RemoteNames.ClientToServer.UpdateMovementState, function(player, payload)
		if type(payload) ~= "table" then
			return
		end

		PlayerControllerService.updateInputState(player, {
			sprinting = payload.sprinting == true,
			crouching = payload.crouching == true,
			jumping = payload.jumping == true,
			movementMode = "Walk",
		})
	end)
end

local function sendMovementProfile(player: Player)
	getRemote(RemoteNames.ServerToClient.MovementProfileUpdated):FireClient(player, {
		profile = PlayerControllerService.getMovementProfile(player),
		accessibility = PlayerExperienceConfig.Accessibility,
		camera = PlayerExperienceConfig.Camera,
	})
end

local function connectPlayerLifecycle()
	table.insert(
		eventConnections,
		Players.PlayerAdded:Connect(function(player)
			characterConnectionsByUserId[player.UserId] = player.CharacterAdded:Connect(function()
				PlayerControllerService.handleCharacterAdded(player)
				sendMovementProfile(player)
			end)
		end)
	)

	table.insert(
		eventConnections,
		Players.PlayerRemoving:Connect(function(player)
			local characterConnection = characterConnectionsByUserId[player.UserId]

			if characterConnection ~= nil then
				characterConnection:Disconnect()
				characterConnectionsByUserId[player.UserId] = nil
			end

			PlayerControllerService.handlePlayerRemoving(player)
			InteractionService.handlePlayerRemoving(player)
		end)
	)

	for _, player in ipairs(Players:GetPlayers()) do
		if characterConnectionsByUserId[player.UserId] == nil then
			characterConnectionsByUserId[player.UserId] = player.CharacterAdded:Connect(function()
				PlayerControllerService.handleCharacterAdded(player)
				sendMovementProfile(player)
			end)
		end

		PlayerControllerService.handleCharacterAdded(player)
		sendMovementProfile(player)
	end
end

local function connectInteractableLifecycle()
	InteractionService.refreshRegistry()

	table.insert(
		eventConnections,
		CollectionService:GetInstanceAddedSignal("LondonInteractable"):Connect(function(instance)
			InteractionRegistry.registerInstance(instance)
		end)
	)

	table.insert(
		eventConnections,
		CollectionService:GetInstanceRemovedSignal("LondonInteractable"):Connect(function(instance)
			InteractionRegistry.unregisterInstance(instance)
		end)
	)
end

function PlayerExperienceService.initialize()
	if initialized then
		return
	end

	registerRemotes()
	connectRemotes()

	FeedbackService.configure(function(player: Player, instructions: { FeedbackInstruction })
		getRemote(RemoteNames.ServerToClient.Feedback):FireClient(player, {
			instructions = instructions,
		})
	end)

	Diagnostics.registerSampler("PlayerExperience", PlayerExperienceService.inspect)
	SnapshotManager.registerProvider("playerExperience", PlayerExperienceService.inspect)

	local ok, err = PlayerExperienceService.validate()

	if not ok then
		error("PlayerExperienceService validation failed: " .. tostring(err), 0)
	end

	initialized = true
	log.success("PlayerExperienceService initialized")
end

function PlayerExperienceService.start()
	if started then
		return
	end

	if not initialized then
		PlayerExperienceService.initialize()
	end

	connectInteractableLifecycle()
	connectPlayerLifecycle()

	EventBus.publishDeferred("PlayerExperience.Ready", {
		namespace = RemoteNames.Namespace,
	})

	started = true
	log.success("PlayerExperienceService started")
end

function PlayerExperienceService.shutdown()
	for _, connection in ipairs(eventConnections) do
		connection:Disconnect()
	end

	for _, connection in pairs(characterConnectionsByUserId) do
		connection:Disconnect()
	end

	for _, disconnect in ipairs(busDisconnects) do
		disconnect()
	end

	table.clear(eventConnections)
	table.clear(characterConnectionsByUserId)
	table.clear(busDisconnects)
	FeedbackService.clear()
	InteractionService.clear()
	started = false
end

function PlayerExperienceService.inspect()
	return {
		initialized = initialized,
		started = started,
		remotes = {
			namespace = RemoteNames.Namespace,
			version = RemoteNames.Version,
			names = RemoteNames,
		},
		playerController = PlayerControllerService.inspect(),
		interactions = InteractionService.inspect(),
	}
end

function PlayerExperienceService.validate(): (boolean, string?)
	local movementOk, movementErr = PlayerControllerService.validate()

	if not movementOk then
		return false, movementErr
	end

	local interactionOk, interactionErr = InteractionService.validate()

	if not interactionOk then
		return false, interactionErr
	end

	return true, nil
end

function PlayerExperienceService.runSelfChecks()
	local movementChecks = PlayerControllerService.runSelfChecks()
	local interactionChecks = InteractionService.runSelfChecks()

	return {
		ok = movementChecks.ok and interactionChecks.ok,
		movement = movementChecks,
		interaction = interactionChecks,
	}
end

return PlayerExperienceService

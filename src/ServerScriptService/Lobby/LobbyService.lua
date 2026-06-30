--!strict
--[[
	LobbyService is the server networking boundary for the lobby runtime.

	It registers remotes through RemoteManager, validates every request, delegates
	party truth to PartyService, and broadcasts structured party/launch updates.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Core = ServerScriptService.Core
local Diagnostics = require(Core.Diagnostics)
local EventBus = require(Core.EventBus)
local Logger = require(Core.Logger)
local RemoteManager = require(Core.RemoteManager)
local SnapshotManager = require(Core.SnapshotManager)

local RemoteNames = require(ReplicatedStorage.Lobby.PartyRemotes.RemoteNames)
local PartyConfig = require(script.Parent.Parties.PartyConfig)
local MatchmakingService = require(script.Parent.Matchmaking.MatchmakingService)
local PartyService = require(script.Parent.Parties.PartyService)
local PartyTypes = require(script.Parent.Parties.PartyTypes)

local LobbyService = {}

type Result = PartyTypes.Result

local log = Logger.scope("LobbyService")
local initialized = false
local started = false
local remoteEvents: { [string]: RemoteEvent } = {}
local eventConnections: { RBXScriptConnection } = {}
local busDisconnects: { () -> () } = {}

local function remoteKey(name: string): string
	return name
end

local function defineRemote(name: string, rateLimit: number?): RemoteEvent
	local remote = RemoteManager.define({
		namespace = RemoteNames.Namespace,
		name = name,
		version = RemoteNames.Version,
		kind = "Event",
		rateLimit = rateLimit,
	}) :: RemoteEvent

	remoteEvents[remoteKey(name)] = remote

	return remote
end

local function getRemote(name: string): RemoteEvent
	local remote = remoteEvents[remoteKey(name)]

	if remote == nil then
		error("Lobby remote not initialized: " .. name, 2)
	end

	return remote
end

local function sendError(player: Player, result: Result)
	getRemote(RemoteNames.ServerToClient.LobbyError):FireClient(player, {
		ok = false,
		code = result.code,
		message = result.message,
		data = result.data,
		party = result.party,
	})
end

local function sendPartyState(player: Player, partyState: any?)
	getRemote(RemoteNames.ServerToClient.PartyStateUpdated):FireClient(player, {
		ok = true,
		party = partyState,
	})
end

local function sendLaunchState(player: Player, payload: any)
	getRemote(RemoteNames.ServerToClient.LaunchStateUpdated):FireClient(player, payload)
end

local function broadcastPartyState(partyState: any?)
	if partyState == nil or partyState.members == nil then
		return
	end

	for _, member in ipairs(partyState.members) do
		local player = Players:GetPlayerByUserId(member.userId)

		if player ~= nil then
			sendPartyState(player, partyState)
		end
	end
end

local function processResult(player: Player, result: Result)
	if result.party ~= nil then
		sendPartyState(player, result.party)
	end

	if not result.ok then
		sendError(player, result)
	end
end

local function validateRemote(player: Player, name: string, ...: any): boolean
	local ok, reason =
		RemoteManager.validateCall(player, RemoteNames.Namespace, name, RemoteNames.Version, ...)

	if not ok then
		sendError(
			player,
			PartyTypes.err(PartyTypes.ResultCode.InvalidRequest, reason or "Request rejected.")
		)
		return false
	end

	return true
end

local function asNumber(value: any): number?
	if type(value) ~= "number" then
		return nil
	end

	return value
end

local function asString(value: any): string?
	if type(value) ~= "string" then
		return nil
	end

	return value
end

local function connectClientRemote(name: string, callback: (Player, any) -> Result?)
	local remote = getRemote(name)
	local connection = remote.OnServerEvent:Connect(function(player: Player, payload: any)
		if not validateRemote(player, name, payload) then
			return
		end

		local ok, result = pcall(callback, player, payload)

		if not ok then
			log.withContext("ERROR", "Lobby remote handler failed", {
				remote = name,
				userId = player.UserId,
				error = tostring(result),
			})
			sendError(
				player,
				PartyTypes.err(PartyTypes.ResultCode.InvalidRequest, "Lobby request failed.")
			)
			return
		end

		if result ~= nil then
			processResult(player, result)
		end
	end)

	table.insert(eventConnections, connection)
end

local function registerRemotes()
	for _, name in pairs(RemoteNames.ClientToServer) do
		defineRemote(name, PartyConfig.RemoteRateLimitPerSecond)
	end

	for _, name in pairs(RemoteNames.ServerToClient) do
		defineRemote(name, nil)
	end
end

local function connectRemotes()
	connectClientRemote(RemoteNames.ClientToServer.CreateParty, function(player)
		return PartyService.createParty(player)
	end)

	connectClientRemote(RemoteNames.ClientToServer.JoinParty, function(player, payload)
		local partyId = if type(payload) == "table" then asString(payload.partyId) else nil
		return PartyService.joinParty(player, partyId or "")
	end)

	connectClientRemote(RemoteNames.ClientToServer.LeaveParty, function(player)
		local result = PartyService.leaveParty(player)

		if result.ok then
			sendPartyState(player, nil)
		end

		return result
	end)

	connectClientRemote(RemoteNames.ClientToServer.KickMember, function(player, payload)
		local targetUserId = if type(payload) == "table"
			then asNumber(payload.targetUserId)
			else nil

		if targetUserId == nil then
			return PartyTypes.err(PartyTypes.ResultCode.InvalidRequest, "targetUserId is required.")
		end

		local result = PartyService.kickMember(player, targetUserId)

		if result.ok then
			local targetPlayer = Players:GetPlayerByUserId(targetUserId)

			if targetPlayer ~= nil then
				sendPartyState(targetPlayer, nil)
				sendError(
					targetPlayer,
					PartyTypes.err(
						PartyTypes.ResultCode.NotInParty,
						"You were removed from the party."
					)
				)
			end
		end

		return result
	end)

	connectClientRemote(RemoteNames.ClientToServer.TransferLeader, function(player, payload)
		local targetUserId = if type(payload) == "table"
			then asNumber(payload.targetUserId)
			else nil

		if targetUserId == nil then
			return PartyTypes.err(PartyTypes.ResultCode.InvalidRequest, "targetUserId is required.")
		end

		return PartyService.transferLeader(player, targetUserId)
	end)

	connectClientRemote(RemoteNames.ClientToServer.SetReady, function(player, payload)
		local ready = if type(payload) == "table" then payload.ready == true else false
		return PartyService.setReady(player, ready)
	end)

	connectClientRemote(RemoteNames.ClientToServer.SelectChapter, function(player, payload)
		local chapterId = if type(payload) == "table" then asString(payload.chapterId) else nil

		if chapterId == nil then
			return PartyTypes.err(PartyTypes.ResultCode.InvalidRequest, "chapterId is required.")
		end

		return PartyService.selectChapter(player, chapterId)
	end)

	connectClientRemote(RemoteNames.ClientToServer.SetLocked, function(player, payload)
		local locked = if type(payload) == "table" then payload.locked == true else false
		return PartyService.setLocked(player, locked)
	end)

	connectClientRemote(RemoteNames.ClientToServer.RequestLaunch, function(player)
		local result = MatchmakingService.requestLaunch(player)

		sendLaunchState(player, {
			ok = result.ok,
			code = result.code,
			message = result.message,
			party = result.party,
			data = result.data,
		})

		return result
	end)

	connectClientRemote(RemoteNames.ClientToServer.RequestState, function(player)
		sendPartyState(player, PartyService.getSerializedPartyForPlayer(player))
		return nil
	end)
end

local function connectEventBus()
	table.insert(
		busDisconnects,
		EventBus.subscribe("Lobby.PartyChanged", function(event)
			if event.payload ~= nil then
				broadcastPartyState(event.payload.party)
			end
		end)
	)

	table.insert(
		busDisconnects,
		EventBus.subscribe("Lobby.LaunchCompleted", function(event)
			if event.payload == nil then
				return
			end

			local partyId = event.payload.partyId
			local result = event.payload.result
			local party = if type(partyId) == "string"
				then PartyService.getPartyById(partyId)
				else nil
			local partyState = if party ~= nil then PartyService.serializeParty(party) else nil

			if partyState ~= nil and partyState.members ~= nil then
				for _, member in ipairs(partyState.members) do
					local player = Players:GetPlayerByUserId(member.userId)

					if player ~= nil then
						sendLaunchState(player, result)
					end
				end
			end
		end)
	)
end

function LobbyService.initialize()
	if initialized then
		return
	end

	registerRemotes()
	connectRemotes()
	connectEventBus()

	Diagnostics.registerSampler("Lobby", LobbyService.inspect)
	SnapshotManager.registerProvider("lobby", LobbyService.inspect)

	local selfChecks = LobbyService.runSelfChecks()

	if not selfChecks.ok then
		error("LobbyService self-checks failed", 0)
	end

	initialized = true

	log.success("LobbyService initialized")
end

function LobbyService.start()
	if started then
		return
	end

	table.insert(
		eventConnections,
		Players.PlayerRemoving:Connect(PartyService.handlePlayerRemoving)
	)

	started = true
	log.success("LobbyService started")
end

function LobbyService.shutdown()
	for _, connection in ipairs(eventConnections) do
		connection:Disconnect()
	end

	for _, disconnect in ipairs(busDisconnects) do
		disconnect()
	end

	table.clear(eventConnections)
	table.clear(busDisconnects)
	started = false
end

function LobbyService.inspect()
	return {
		initialized = initialized,
		started = started,
		parties = PartyService.inspect(),
		matchmaking = MatchmakingService.inspect(),
	}
end

function LobbyService.validate(): (boolean, string?)
	local partyOk, partyErr = PartyService.validate()

	if not partyOk then
		return false, partyErr
	end

	local matchmakingOk, matchmakingErr = MatchmakingService.validate()

	if not matchmakingOk then
		return false, matchmakingErr
	end

	return true, nil
end

function LobbyService.runSelfChecks()
	local partyChecks = PartyService.runSelfChecks()
	local matchmakingChecks = MatchmakingService.runSelfChecks()

	return {
		ok = partyChecks.ok and matchmakingChecks.ok,
		party = partyChecks,
		matchmaking = matchmakingChecks,
	}
end

return LobbyService

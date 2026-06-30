--!strict
--[[
	PortalService orchestrates the cinematic lobby portal runtime.

	It owns remotes, lifecycle, EventBus integration, and the public service API.
	Focused portal modules own state transitions, occupants, validation,
	countdowns, physical zone tracking, and atmosphere cues.
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

local PortalRemoteNames = require(ReplicatedStorage.Lobby.PortalRemotes.PortalRemoteNames)
local PartyService = require(ServerScriptService.Lobby.Parties.PartyService)
local PortalAtmosphere = require(script.Parent.PortalAtmosphere)
local PortalConfig = require(script.Parent.PortalConfig)
local PortalCountdown = require(script.Parent.PortalCountdown)
local PortalOccupants = require(script.Parent.PortalOccupants)
local PortalStateMachine = require(script.Parent.PortalStateMachine)
local PortalTypes = require(script.Parent.PortalTypes)
local PortalValidator = require(script.Parent.PortalValidator)
local PortalZoneTracker = require(script.Parent.PortalZoneTracker)

local PortalService = {}

type PortalRuntime = PortalTypes.PortalRuntime
type PortalResult = PortalTypes.PortalResult

local log = Logger.scope("PortalService")
local initialized = false
local started = false
local portals: { [string]: PortalRuntime } = {}
local playerToPortal: { [number]: string } = {}
local eventConnections: { RBXScriptConnection } = {}
local busDisconnects: { () -> () } = {}
local remoteEvents: { [string]: RemoteEvent } = {}

local function getPortal(portalId: string?): PortalRuntime?
	return PortalOccupants.getPortal(portals, portalId)
end

local function serializePortal(portal: PortalRuntime)
	return PortalOccupants.serialize(portal)
end

local function defineRemote(name: string, rateLimit: number?): RemoteEvent
	local remote = RemoteManager.define({
		namespace = PortalRemoteNames.Namespace,
		name = name,
		version = PortalRemoteNames.Version,
		kind = "Event",
		rateLimit = rateLimit,
	}) :: RemoteEvent

	remoteEvents[name] = remote

	return remote
end

local function getRemote(name: string): RemoteEvent
	local remote = remoteEvents[name]

	if remote == nil then
		error("Portal remote not initialized: " .. name, 2)
	end

	return remote
end

local function sendAllStates(player: Player)
	local states = {}

	for portalId, portal in pairs(portals) do
		states[portalId] = serializePortal(portal)
	end

	getRemote(PortalRemoteNames.ServerToClient.PortalStateUpdated):FireClient(player, {
		ok = true,
		portals = states,
	})
end

local function sendError(player: Player, result: PortalResult)
	getRemote(PortalRemoteNames.ServerToClient.PortalError):FireClient(player, {
		ok = false,
		code = result.code,
		message = result.message,
		state = result.state,
		data = result.data,
	})
end

local function broadcastState(portal: PortalRuntime)
	getRemote(PortalRemoteNames.ServerToClient.PortalStateUpdated):FireAllClients({
		ok = true,
		portal = serializePortal(portal),
	})
end

local function setPortalState(
	portal: PortalRuntime,
	state: PortalTypes.PortalState,
	reason: string,
	data: any?
): boolean
	local changed = PortalStateMachine.setState(portal, state, reason, data, broadcastState)

	if changed then
		EventBus.publishDeferred("LobbyPortal.StateChanged", {
			portal = serializePortal(portal),
			reason = reason,
			data = data,
		})
	end

	return changed
end

local function validateReadyToLaunch(player: Player, portal: PortalRuntime): PortalResult
	return PortalValidator.validateReadyToLaunch(player, portal, serializePortal)
end

local function fireAtmosphereCue(portal: PortalRuntime, cue: string, data: any?)
	PortalAtmosphere.fireCue(portal, cue, data, function(player, payload)
		getRemote(PortalRemoteNames.ServerToClient.PortalAtmosphereCue):FireClient(player, payload)
	end)
end

local function makeCountdownContext(): PortalCountdown.Context
	return {
		serializePortal = serializePortal,
		setState = setPortalState,
		validateReadyToLaunch = validateReadyToLaunch,
		fireAtmosphereCue = fireAtmosphereCue,
		refreshPortalState = PortalService.refreshPortalState,
	}
end

local function failPortal(portal: PortalRuntime, reason: string, data: any?)
	PortalCountdown.failPortal(portal, reason, data, makeCountdownContext())
end

local function findPartyForPortal(portal: PortalRuntime)
	if portal.partyId == nil then
		return nil
	end

	return PartyService.getPartyById(portal.partyId)
end

local function refreshPortalRuntime(portal: PortalRuntime, reason: string)
	if
		portal.state == PortalConfig.PortalStates.Launching
		or portal.state == PortalConfig.PortalStates.Transitioning
	then
		return
	end

	PortalOccupants.clearPartyIfEmpty(portal)

	if PortalOccupants.count(portal) == 0 then
		setPortalState(portal, PortalConfig.PortalStates.Idle, reason, nil)
		return
	end

	if portal.cooldownUntil > os.clock() then
		setPortalState(portal, PortalConfig.PortalStates.Cooldown, reason, nil)
		return
	end

	local party = findPartyForPortal(portal)

	if party == nil then
		setPortalState(portal, PortalConfig.PortalStates.WaitingForParty, reason, nil)
		return
	end

	local present = PortalValidator.validatePartyPresence(portal, party)
	local launchValidation = PartyService.validatePartyForLaunch(party)

	if present and launchValidation.ok then
		setPortalState(portal, PortalConfig.PortalStates.ReadyToLaunch, reason, nil)
	elseif present then
		setPortalState(portal, PortalConfig.PortalStates.Boarding, reason, {
			party = launchValidation.party,
			code = launchValidation.code,
			message = launchValidation.message,
		})
	else
		setPortalState(portal, PortalConfig.PortalStates.WaitingForParty, reason, nil)
	end
end

local function registerRemotes()
	for _, name in pairs(PortalRemoteNames.ClientToServer) do
		defineRemote(name, PortalConfig.RemoteRateLimitPerSecond)
	end

	for _, name in pairs(PortalRemoteNames.ServerToClient) do
		defineRemote(name, nil)
	end
end

local function validateRemote(player: Player, name: string, ...: any): boolean
	local ok, reason = RemoteManager.validateCall(
		player,
		PortalRemoteNames.Namespace,
		name,
		PortalRemoteNames.Version,
		...
	)

	if not ok then
		sendError(
			player,
			PortalTypes.err(
				PortalTypes.ResultCode.InvalidRequest,
				reason or "Portal request rejected."
			)
		)
		return false
	end

	return true
end

local function processResult(player: Player, result: PortalResult)
	if result.state ~= nil then
		getRemote(PortalRemoteNames.ServerToClient.PortalStateUpdated):FireClient(player, {
			ok = result.ok,
			portal = result.state,
		})
	end

	if not result.ok then
		sendError(player, result)
	end
end

local function connectClientRemote(name: string, callback: (Player, any) -> PortalResult?)
	local remote = getRemote(name)
	local connection = remote.OnServerEvent:Connect(function(player: Player, payload: any)
		if not validateRemote(player, name, payload) then
			return
		end

		local ok, result = pcall(callback, player, payload)

		if not ok then
			log.withContext("ERROR", "Portal remote handler failed", {
				remote = name,
				userId = player.UserId,
				error = tostring(result),
			})
			sendError(
				player,
				PortalTypes.err(PortalTypes.ResultCode.InvalidRequest, "Portal request failed.")
			)
			return
		end

		if result ~= nil then
			processResult(player, result)
		end
	end)

	table.insert(eventConnections, connection)
end

local function connectRemotes()
	connectClientRemote(PortalRemoteNames.ClientToServer.RequestBoard, function(player, payload)
		return PortalService.boardPlayer(player, PortalOccupants.getPayloadPortalId(payload))
	end)

	connectClientRemote(PortalRemoteNames.ClientToServer.RequestExit, function(player, payload)
		return PortalService.exitPlayer(
			player,
			PortalOccupants.getPayloadPortalId(payload),
			"ClientExit"
		)
	end)

	connectClientRemote(PortalRemoteNames.ClientToServer.RequestLaunch, function(player, payload)
		return PortalService.requestLaunch(player, PortalOccupants.getPayloadPortalId(payload))
	end)

	connectClientRemote(PortalRemoteNames.ClientToServer.RequestState, function(player)
		sendAllStates(player)
		return nil
	end)
end

local function connectEventBus()
	table.insert(
		busDisconnects,
		EventBus.subscribe("Lobby.PartyChanged", function(event)
			if event.payload == nil or event.payload.party == nil then
				return
			end

			local partyId = event.payload.party.id

			for _, portal in pairs(portals) do
				if portal.partyId == partyId then
					if
						portal.state == PortalConfig.PortalStates.Countdown
						or portal.state == PortalConfig.PortalStates.Transitioning
					then
						local leader = if portal.leaderUserId ~= nil
							then Players:GetPlayerByUserId(portal.leaderUserId)
							else nil

						if leader == nil or not validateReadyToLaunch(leader, portal).ok then
							failPortal(portal, "PartyChangedDuringPortalLaunch", nil)
						end
					else
						refreshPortalRuntime(portal, "PartyChanged")
					end
				end
			end
		end)
	)

	table.insert(
		busDisconnects,
		EventBus.subscribe("Lobby.PartyDestroyed", function(event)
			if event.payload == nil then
				return
			end

			local partyId = event.payload.partyId

			for _, portal in pairs(portals) do
				if portal.partyId == partyId then
					failPortal(portal, "PartyDestroyed", nil)
					portal.partyId = nil
					portal.leaderUserId = nil
				end
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

			for _, portal in pairs(portals) do
				if portal.partyId == partyId then
					if result ~= nil and result.ok == false then
						failPortal(portal, result.message or "LaunchFailed", result)
					else
						setPortalState(
							portal,
							PortalConfig.PortalStates.Launching,
							"LaunchCompleted",
							result
						)
					end
				end
			end
		end)
	)
end

function PortalService.boardPlayer(player: Player, portalId: string): PortalResult
	local portal = getPortal(portalId)

	if portal == nil then
		return PortalTypes.err(PortalTypes.ResultCode.PortalNotFound, "Portal was not found.")
	end

	if not portal.definition.enabled then
		return PortalTypes.err(
			PortalTypes.ResultCode.PortalDisabled,
			"Portal is disabled.",
			serializePortal(portal)
		)
	end

	if portal.cooldownUntil > os.clock() then
		return PortalTypes.err(
			PortalTypes.ResultCode.Cooldown,
			"Portal is cooling down.",
			serializePortal(portal)
		)
	end

	if
		PortalZoneTracker.hasRegisteredZones(portal.id)
		and not PortalZoneTracker.isPlayerInsideRegisteredZone(player, portal.id)
	then
		return PortalTypes.err(
			PortalTypes.ResultCode.ZoneRequired,
			"Player must be inside the server portal zone before boarding.",
			serializePortal(portal)
		)
	end

	if
		not PortalZoneTracker.hasRegisteredZones(portal.id)
		and not PortalConfig.AllowRemoteBoardingWithoutRegisteredZones
	then
		return PortalTypes.err(
			PortalTypes.ResultCode.ZoneRequired,
			"Portal has no registered server zone.",
			serializePortal(portal)
		)
	end

	local currentPortalId = playerToPortal[player.UserId]

	if currentPortalId ~= nil and currentPortalId ~= portal.id then
		PortalService.exitPlayer(player, currentPortalId, "MovedToDifferentPortal")
	end

	if
		portal.occupants[player.UserId] == nil
		and PortalOccupants.count(portal) >= portal.definition.maxPlayers
	then
		return PortalTypes.err(
			PortalTypes.ResultCode.PortalFull,
			"Portal is full.",
			serializePortal(portal)
		)
	end

	local party = PartyService.getPartyForPlayer(player)

	if party == nil and PortalConfig.AutoCreateSoloPartyOnBoard then
		local createResult = PartyService.createParty(player)

		if not createResult.ok then
			return PortalTypes.err(
				createResult.code,
				createResult.message,
				serializePortal(portal),
				{
					party = createResult.party,
				}
			)
		end

		party = PartyService.getPartyForPlayer(player)
	end

	if party == nil then
		return PortalTypes.err(
			PortalTypes.ResultCode.NotInParty,
			"Player must create or join a party before boarding.",
			serializePortal(portal)
		)
	end

	if portal.partyId ~= nil and portal.partyId ~= party.id then
		return PortalTypes.err(
			PortalTypes.ResultCode.PartyMismatch,
			"Portal is already reserved for another party.",
			serializePortal(portal)
		)
	end

	if party.selectedChapterId ~= portal.definition.chapterId then
		return PortalTypes.err(
			PortalTypes.ResultCode.InvalidChapter,
			"Party selected chapter does not match this portal.",
			serializePortal(portal)
		)
	end

	portal.occupants[player.UserId] = os.clock()
	portal.partyId = party.id
	portal.leaderUserId = party.leaderUserId
	playerToPortal[player.UserId] = portal.id

	fireAtmosphereCue(portal, PortalConfig.AtmosphereCues.FogThickening, {
		reason = "Boarded",
		userId = player.UserId,
	})
	refreshPortalRuntime(portal, "PlayerBoarded")

	return PortalTypes.ok("Player boarded portal.", serializePortal(portal))
end

function PortalService.exitPlayer(player: Player, portalId: string?, reason: string?): PortalResult
	local portal = getPortal(portalId or playerToPortal[player.UserId])

	if portal == nil then
		return PortalTypes.err(PortalTypes.ResultCode.PortalNotFound, "Portal was not found.")
	end

	if portal.occupants[player.UserId] == nil then
		return PortalTypes.err(
			PortalTypes.ResultCode.NotInPortal,
			"Player is not inside this portal.",
			serializePortal(portal)
		)
	end

	portal.occupants[player.UserId] = nil
	playerToPortal[player.UserId] = nil

	if
		portal.state == PortalConfig.PortalStates.Countdown
		or portal.state == PortalConfig.PortalStates.Transitioning
	then
		failPortal(portal, reason or "PlayerExitedDuringPortalLaunch", nil)
	else
		refreshPortalRuntime(portal, reason or "PlayerExited")
	end

	return PortalTypes.ok("Player exited portal.", serializePortal(portal))
end

function PortalService.requestLaunch(player: Player, portalId: string): PortalResult
	local portal = getPortal(portalId)

	if portal == nil then
		return PortalTypes.err(PortalTypes.ResultCode.PortalNotFound, "Portal was not found.")
	end

	if
		portal.state == PortalConfig.PortalStates.Countdown
		or portal.state == PortalConfig.PortalStates.Transitioning
		or portal.state == PortalConfig.PortalStates.Launching
	then
		return PortalTypes.err(
			PortalTypes.ResultCode.LaunchInProgress,
			"Portal launch is already in progress.",
			serializePortal(portal)
		)
	end

	return PortalCountdown.start(
		player,
		portal,
		makeCountdownContext(),
		PortalService.transitionToLaunch
	)
end

function PortalService.transitionToLaunch(
	player: Player,
	portalId: string,
	launchToken: number?
): PortalResult
	local portal = getPortal(portalId)

	if portal == nil then
		return PortalTypes.err(PortalTypes.ResultCode.PortalNotFound, "Portal was not found.")
	end

	return PortalCountdown.transitionToLaunch(player, portal, launchToken, makeCountdownContext())
end

function PortalService.playerEnteredZone(player: Player, portalId: string): PortalResult
	return PortalService.boardPlayer(player, portalId)
end

function PortalService.playerExitedZone(player: Player, portalId: string): PortalResult
	return PortalService.exitPlayer(player, portalId, "ZoneExit")
end

function PortalService.registerPortalZone(portalId: string, zonePart: BasePart): (boolean, string?)
	return PortalZoneTracker.registerZone(
		getPortal(portalId),
		portalId,
		zonePart,
		PortalService.playerEnteredZone,
		PortalService.playerExitedZone
	)
end

function PortalService.refreshPortalState(portalId: string, reason: string)
	local portal = getPortal(portalId)

	if portal ~= nil then
		refreshPortalRuntime(portal, reason)
	end
end

function PortalService.handlePlayerRemoving(player: Player)
	local portalId = playerToPortal[player.UserId]

	if portalId == nil then
		return
	end

	local portal = getPortal(portalId)

	if portal == nil then
		playerToPortal[player.UserId] = nil
		return
	end

	portal.occupants[player.UserId] = nil
	playerToPortal[player.UserId] = nil

	if
		portal.state == PortalConfig.PortalStates.Countdown
		or portal.state == PortalConfig.PortalStates.Transitioning
	then
		failPortal(portal, "Player disconnected during portal launch.", nil)
	else
		refreshPortalRuntime(portal, "PlayerDisconnected")
	end
end

function PortalService.initialize()
	if initialized then
		return
	end

	portals = PortalOccupants.initializePortals()
	registerRemotes()
	connectRemotes()
	connectEventBus()

	Diagnostics.registerSampler("LobbyPortal", PortalService.inspect)
	SnapshotManager.registerProvider("lobbyPortal", PortalService.inspect)

	local checks = PortalService.runSelfChecks()

	if not checks.ok then
		error("PortalService self-checks failed", 0)
	end

	initialized = true
	log.success("PortalService initialized")
end

function PortalService.start()
	if started then
		return
	end

	table.insert(
		eventConnections,
		Players.PlayerRemoving:Connect(PortalService.handlePlayerRemoving)
	)
	started = true
	log.success("PortalService started")
end

function PortalService.shutdown()
	for _, connection in ipairs(eventConnections) do
		connection:Disconnect()
	end

	for _, disconnect in ipairs(busDisconnects) do
		disconnect()
	end

	PortalCountdown.cleanup()
	PortalZoneTracker.cleanup()

	table.clear(eventConnections)
	table.clear(busDisconnects)
	started = false
end

function PortalService.inspect()
	local snapshot = {}

	for portalId, portal in pairs(portals) do
		snapshot[portalId] = serializePortal(portal)
	end

	return {
		initialized = initialized,
		started = started,
		portalCount = PortalService.count(),
		portals = snapshot,
		countdown = PortalCountdown.inspect(),
		zones = PortalZoneTracker.inspect(),
	}
end

function PortalService.count(): number
	local count = 0

	for _ in pairs(portals) do
		count += 1
	end

	return count
end

function PortalService.validate(): (boolean, string?)
	for portalId, portal in pairs(portals) do
		if portal.id ~= portalId then
			return false, "Portal id mismatch"
		end

		if portal.definition.id ~= portalId then
			return false, "Portal definition id mismatch"
		end

		if portal.definition.maxPlayers > PortalConfig.MaxPortalOccupants then
			return false, "Portal max players exceeds global limit"
		end
	end

	return true, nil
end

function PortalService.runSelfChecks()
	local defaultPortal = PortalConfig.getPortal(PortalConfig.DefaultPortalId)
	local states = PortalConfig.PortalStates
	local cues = PortalConfig.AtmosphereCues

	local ok = defaultPortal ~= nil
		and defaultPortal.enabled == true
		and states.Idle == "Idle"
		and states.Countdown == "Countdown"
		and cues.CarriageLanternFlicker ~= nil
		and cues.ChapterTransition ~= nil

	return {
		ok = ok,
		defaultPortalExists = defaultPortal ~= nil,
		stateCount = 9,
		cueCount = 10,
	}
end

return PortalService

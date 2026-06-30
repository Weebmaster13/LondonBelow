--!strict
--[[
	PortalService owns cinematic lobby portal state.

	It tracks who is inside each portal zone, validates party readiness and
	presence, drives countdown/transition atmosphere hooks, and delegates final
	launch authority to MatchmakingService. It never teleports directly.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Core = ServerScriptService.Core
local Diagnostics = require(Core.Diagnostics)
local EventBus = require(Core.EventBus)
local Logger = require(Core.Logger)
local RemoteManager = require(Core.RemoteManager)
local Scheduler = require(Core.Scheduler)
local SnapshotManager = require(Core.SnapshotManager)

local PortalRemoteNames = require(ReplicatedStorage.Lobby.PortalRemotes.PortalRemoteNames)
local MatchmakingService = require(ServerScriptService.Lobby.Matchmaking.MatchmakingService)
local PartyService = require(ServerScriptService.Lobby.Parties.PartyService)
local PartyTypes = require(ServerScriptService.Lobby.Parties.PartyTypes)
local PortalConfig = require(script.Parent.PortalConfig)
local PortalTypes = require(script.Parent.PortalTypes)

local PortalService = {}

type PortalDefinition = PortalTypes.PortalDefinition
type PortalRuntime = PortalTypes.PortalRuntime
type PortalResult = PortalTypes.PortalResult
type TaskHandle = Scheduler.TaskHandle

local log = Logger.scope("PortalService")
local initialized = false
local started = false
local portals: { [string]: PortalRuntime } = {}
local playerToPortal: { [number]: string } = {}
local zoneConnections: { RBXScriptConnection } = {}
local eventConnections: { RBXScriptConnection } = {}
local busDisconnects: { () -> () } = {}
local countdownHandles: { [string]: TaskHandle } = {}
local cooldownHandles: { [string]: TaskHandle } = {}
local transitionHandles: { [string]: { TaskHandle } } = {}
local zoneContactCounts: { [string]: { [number]: number } } = {}
local registeredZoneCounts: { [string]: number } = {}
local remoteEvents: { [string]: RemoteEvent } = {}
local cancelCountdown: (PortalRuntime, string) -> ()
local scheduleCooldown: (PortalRuntime, string) -> ()

local ALLOWED_TRANSITIONS: { [string]: { [string]: boolean } } = {
	Idle = {
		WaitingForParty = true,
		Boarding = true,
		ReadyToLaunch = true,
		Failed = true,
		Cooldown = true,
	},
	WaitingForParty = {
		Idle = true,
		Boarding = true,
		ReadyToLaunch = true,
		Failed = true,
		Cooldown = true,
	},
	Boarding = {
		Idle = true,
		WaitingForParty = true,
		ReadyToLaunch = true,
		Failed = true,
		Cooldown = true,
	},
	ReadyToLaunch = {
		Idle = true,
		WaitingForParty = true,
		Boarding = true,
		Countdown = true,
		Failed = true,
		Cooldown = true,
	},
	Countdown = {
		Failed = true,
		Transitioning = true,
	},
	Transitioning = {
		Failed = true,
		Launching = true,
	},
	Launching = {
		Failed = true,
		Launching = true,
	},
	Failed = {
		Cooldown = true,
		Idle = true,
	},
	Cooldown = {
		Idle = true,
		WaitingForParty = true,
		Boarding = true,
		ReadyToLaunch = true,
		Failed = true,
	},
}

local function now(): number
	return os.clock()
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

local function occupantCount(portal: PortalRuntime): number
	local count = 0

	for _ in pairs(portal.occupants) do
		count += 1
	end

	return count
end

local function getPortal(portalId: string?): PortalRuntime?
	return portals[portalId or PortalConfig.DefaultPortalId]
end

local function getPayloadPortalId(payload: any): string
	if type(payload) == "table" and type(payload.portalId) == "string" then
		return payload.portalId
	end

	return PortalConfig.DefaultPortalId
end

local function getPlayersInPortal(portal: PortalRuntime): { Player }
	local players = {}

	for userId in pairs(portal.occupants) do
		local player = Players:GetPlayerByUserId(userId)

		if player ~= nil then
			table.insert(players, player)
		end
	end

	return players
end

local function serializePartyMembers(party: PartyTypes.Party?)
	if party == nil then
		return {}
	end

	local serialized = PartyService.serializeParty(party)

	return serialized.members or {}
end

local function serializePortal(portal: PortalRuntime)
	local occupants = {}

	for userId, enteredAt in pairs(portal.occupants) do
		local player = Players:GetPlayerByUserId(userId)

		table.insert(occupants, {
			userId = userId,
			name = if player ~= nil then player.Name else "Unknown",
			enteredAt = enteredAt,
			isLeader = portal.leaderUserId == userId,
		})
	end

	table.sort(occupants, function(left, right)
		return left.enteredAt < right.enteredAt
	end)

	return {
		id = portal.id,
		displayName = portal.definition.displayName,
		portalType = portal.definition.portalType,
		chapterId = portal.definition.chapterId,
		state = portal.state,
		occupants = occupants,
		occupantCount = #occupants,
		maxPlayers = portal.definition.maxPlayers,
		leaderUserId = portal.leaderUserId,
		partyId = portal.partyId,
		countdownRemaining = portal.countdownRemaining,
		cooldownRemaining = math.max(0, portal.cooldownUntil - now()),
		lastFailure = portal.lastFailure,
		stateEnteredAt = portal.stateEnteredAt,
		launchToken = portal.launchToken,
		updatedAt = portal.updatedAt,
	}
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
	local payload = {
		ok = true,
		portal = serializePortal(portal),
	}

	getRemote(PortalRemoteNames.ServerToClient.PortalStateUpdated):FireAllClients(payload)
end

local function fireAtmosphereCue(portal: PortalRuntime, cue: string, data: any?)
	local payload = {
		portalId = portal.id,
		portalType = portal.definition.portalType,
		cue = cue,
		data = data,
	}

	for _, player in ipairs(getPlayersInPortal(portal)) do
		getRemote(PortalRemoteNames.ServerToClient.PortalAtmosphereCue):FireClient(player, payload)
	end

	EventBus.publishDeferred("LobbyPortal.AtmosphereCue", payload)
end

local function setPortalState(
	portal: PortalRuntime,
	state: PortalTypes.PortalState,
	reason: string,
	data: any?
)
	if portal.state == state and state ~= PortalConfig.PortalStates.Countdown then
		return
	end

	local allowed = ALLOWED_TRANSITIONS[portal.state]

	if allowed ~= nil and not allowed[state] and portal.state ~= state then
		log.withContext("ERROR", "Rejected invalid portal state transition", {
			portalId = portal.id,
			from = portal.state,
			to = state,
			reason = reason,
		})
		return
	end

	portal.state = state
	portal.stateEnteredAt = now()
	portal.updatedAt = now()

	log.withContext("INFO", "Portal state changed", {
		portalId = portal.id,
		state = state,
		reason = reason,
		partyId = portal.partyId,
		occupants = occupantCount(portal),
	})

	EventBus.publishDeferred("LobbyPortal.StateChanged", {
		portal = serializePortal(portal),
		reason = reason,
		data = data,
	})

	broadcastState(portal)
end

local function hasRegisteredZones(portalId: string): boolean
	return (registeredZoneCounts[portalId] or 0) > 0
end

local function isPlayerInsideRegisteredZone(player: Player, portalId: string): boolean
	local contacts = zoneContactCounts[portalId]

	return contacts ~= nil and (contacts[player.UserId] or 0) > 0
end

local function addTransitionHandle(portal: PortalRuntime, handle: TaskHandle)
	local handles = transitionHandles[portal.id]

	if handles == nil then
		handles = {}
		transitionHandles[portal.id] = handles
	end

	table.insert(handles, handle)
end

local function cancelTransitionTasks(portal: PortalRuntime)
	local handles = transitionHandles[portal.id]

	if handles == nil then
		return
	end

	for _, handle in ipairs(handles) do
		Scheduler.cancel(handle)
	end

	transitionHandles[portal.id] = nil
end

local function beginLaunchAttempt(portal: PortalRuntime): number
	portal.launchToken += 1
	return portal.launchToken
end

local function failPortal(portal: PortalRuntime, reason: string, data: any?)
	cancelCountdown(portal, reason)
	cancelTransitionTasks(portal)
	portal.lastFailure = reason
	setPortalState(portal, PortalConfig.PortalStates.Failed, reason, data)

	addTransitionHandle(
		portal,
		Scheduler.delay(PortalConfig.FailedStateHoldSeconds, function()
			if portal.state == PortalConfig.PortalStates.Failed then
				transitionHandles[portal.id] = nil
				scheduleCooldown(portal, reason)
			end
		end, "PortalFailedHold:" .. portal.id, "LobbyPortal", { "Portal", "Failure" })
	)
end

cancelCountdown = function(portal: PortalRuntime, _reason: string)
	local handle = countdownHandles[portal.id]

	if handle ~= nil then
		Scheduler.cancel(handle)
		countdownHandles[portal.id] = nil
	end

	portal.countdownRemaining = 0
end

scheduleCooldown = function(portal: PortalRuntime, reason: string)
	local existing = cooldownHandles[portal.id]

	if existing ~= nil then
		Scheduler.cancel(existing)
	end

	portal.cooldownUntil = now() + portal.definition.cooldownSeconds
	setPortalState(portal, PortalConfig.PortalStates.Cooldown, reason, nil)

	cooldownHandles[portal.id] = Scheduler.delay(portal.definition.cooldownSeconds, function()
		cooldownHandles[portal.id] = nil
		PortalService.refreshPortalState(portal.id, "CooldownComplete")
	end, "PortalCooldown:" .. portal.id, "LobbyPortal", { "Portal", "Cooldown" })
end

local function clearPortalPartyIfEmpty(portal: PortalRuntime)
	if occupantCount(portal) > 0 then
		return
	end

	portal.partyId = nil
	portal.leaderUserId = nil
	portal.lastFailure = nil
	portal.countdownRemaining = 0
end

local function findPartyForPortal(portal: PortalRuntime): PartyTypes.Party?
	if portal.partyId == nil then
		return nil
	end

	return PartyService.getPartyById(portal.partyId)
end

local function validatePartyPresence(
	portal: PortalRuntime,
	party: PartyTypes.Party
): (boolean, string?, any?)
	local missing = {}

	for _, member in ipairs(serializePartyMembers(party)) do
		if portal.occupants[member.userId] == nil then
			table.insert(missing, member)
		end
	end

	if #missing > 0 then
		return false,
			"Every party member must be inside the portal zone.",
			{
				missing = missing,
			}
	end

	return true, nil, nil
end

local function validateReadyToLaunch(player: Player, portal: PortalRuntime): PortalResult
	if portal.cooldownUntil > now() then
		return PortalTypes.err(
			PortalTypes.ResultCode.Cooldown,
			"Portal is cooling down.",
			serializePortal(portal),
			{
				remaining = portal.cooldownUntil - now(),
			}
		)
	end

	if portal.occupants[player.UserId] == nil then
		return PortalTypes.err(
			PortalTypes.ResultCode.NotInPortal,
			"Player is not inside the portal.",
			serializePortal(portal)
		)
	end

	local party = PartyService.getPartyForPlayer(player)

	if party == nil then
		return PortalTypes.err(
			PortalTypes.ResultCode.NotInParty,
			"Player must be in a party before launching.",
			serializePortal(portal)
		)
	end

	if portal.partyId ~= nil and portal.partyId ~= party.id then
		return PortalTypes.err(
			PortalTypes.ResultCode.PartyMismatch,
			"Portal is already assigned to another party.",
			serializePortal(portal)
		)
	end

	if party.leaderUserId ~= player.UserId then
		return PortalTypes.err(
			PortalTypes.ResultCode.NotLeader,
			"Only the party leader can launch from a portal.",
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

	local present, presenceErr, presenceData = validatePartyPresence(portal, party)

	if not present then
		return PortalTypes.err(
			PortalTypes.ResultCode.PartyNotPresent,
			presenceErr or "Party is not fully inside the portal.",
			serializePortal(portal),
			presenceData
		)
	end

	local launchValidation = PartyService.validatePartyForLaunch(party)

	if not launchValidation.ok then
		local code = if launchValidation.code == PartyTypes.ResultCode.NotReady
			then PortalTypes.ResultCode.PartyNotReady
			else launchValidation.code

		return PortalTypes.err(code, launchValidation.message, serializePortal(portal), {
			party = launchValidation.party,
		})
	end

	return PortalTypes.ok("Portal can launch.", serializePortal(portal))
end

local function refreshPortalRuntime(portal: PortalRuntime, reason: string)
	if
		portal.state == PortalConfig.PortalStates.Launching
		or portal.state == PortalConfig.PortalStates.Transitioning
	then
		return
	end

	clearPortalPartyIfEmpty(portal)

	if occupantCount(portal) == 0 then
		setPortalState(portal, PortalConfig.PortalStates.Idle, reason, nil)
		return
	end

	if portal.cooldownUntil > now() then
		setPortalState(portal, PortalConfig.PortalStates.Cooldown, reason, nil)
		return
	end

	local party = findPartyForPortal(portal)

	if party == nil then
		setPortalState(portal, PortalConfig.PortalStates.WaitingForParty, reason, nil)
		return
	end

	local present = validatePartyPresence(portal, party)
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

local function getPlayerFromHit(hit: BasePart): Player?
	local character = hit:FindFirstAncestorOfClass("Model")

	if character == nil then
		return nil
	end

	return Players:GetPlayerFromCharacter(character)
end

local function initializePortals()
	for portalId, definition in pairs(PortalConfig.Portals) do
		local portal: PortalRuntime = {
			id = portalId,
			definition = definition :: PortalDefinition,
			state = PortalConfig.PortalStates.Idle,
			occupants = {},
			leaderUserId = nil,
			partyId = nil,
			countdownRemaining = 0,
			cooldownUntil = 0,
			lastFailure = nil,
			stateEnteredAt = now(),
			launchToken = 0,
			updatedAt = now(),
		}

		portals[portalId] = portal
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
		return PortalService.boardPlayer(player, getPayloadPortalId(payload))
	end)

	connectClientRemote(PortalRemoteNames.ClientToServer.RequestExit, function(player, payload)
		return PortalService.exitPlayer(player, getPayloadPortalId(payload), "ClientExit")
	end)

	connectClientRemote(PortalRemoteNames.ClientToServer.RequestLaunch, function(player, payload)
		return PortalService.requestLaunch(player, getPayloadPortalId(payload))
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

local function startCountdown(player: Player, portal: PortalRuntime): PortalResult
	if countdownHandles[portal.id] ~= nil then
		return PortalTypes.err(
			PortalTypes.ResultCode.LaunchInProgress,
			"Portal countdown is already running.",
			serializePortal(portal)
		)
	end

	local validation = validateReadyToLaunch(player, portal)

	if not validation.ok then
		return validation
	end

	local launchToken = beginLaunchAttempt(portal)
	portal.countdownRemaining = portal.definition.countdownSeconds
	setPortalState(portal, PortalConfig.PortalStates.ReadyToLaunch, "LaunchRequested", nil)
	fireAtmosphereCue(portal, PortalConfig.AtmosphereCues.CarriageLanternFlicker, {
		countdown = portal.countdownRemaining,
	})
	setPortalState(portal, PortalConfig.PortalStates.Countdown, "CountdownStarted", {
		countdown = portal.countdownRemaining,
	})

	countdownHandles[portal.id] = Scheduler.interval(1, function()
		if portal.launchToken ~= launchToken then
			return
		end

		local leader = Players:GetPlayerByUserId(player.UserId)
		local currentValidation = if leader ~= nil
			then validateReadyToLaunch(leader, portal)
			else PortalTypes.err(
				PortalTypes.ResultCode.NotLeader,
				"Party leader left during countdown.",
				serializePortal(portal)
			)

		if not currentValidation.ok then
			failPortal(portal, currentValidation.message, currentValidation)
			return
		end

		portal.countdownRemaining -= 1

		if portal.countdownRemaining <= 0 then
			local handle = countdownHandles[portal.id]

			if handle ~= nil then
				Scheduler.cancel(handle)
				countdownHandles[portal.id] = nil
			end

			PortalService.transitionToLaunch(leader :: Player, portal.id, launchToken)
			return
		end

		fireAtmosphereCue(portal, PortalConfig.AtmosphereCues.Heartbeat, {
			countdown = portal.countdownRemaining,
		})
		setPortalState(portal, PortalConfig.PortalStates.Countdown, "CountdownTick", {
			countdown = portal.countdownRemaining,
		})
	end, "PortalCountdown:" .. portal.id, "LobbyPortal", { "Portal", "Countdown" })

	return PortalTypes.ok("Portal countdown started.", serializePortal(portal))
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

	if portal.cooldownUntil > now() then
		return PortalTypes.err(
			PortalTypes.ResultCode.Cooldown,
			"Portal is cooling down.",
			serializePortal(portal)
		)
	end

	if hasRegisteredZones(portal.id) and not isPlayerInsideRegisteredZone(player, portal.id) then
		return PortalTypes.err(
			PortalTypes.ResultCode.ZoneRequired,
			"Player must be inside the server portal zone before boarding.",
			serializePortal(portal)
		)
	end

	if
		not hasRegisteredZones(portal.id)
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
		and occupantCount(portal) >= portal.definition.maxPlayers
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

	portal.occupants[player.UserId] = now()
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

	return startCountdown(player, portal)
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

	if launchToken ~= nil and portal.launchToken ~= launchToken then
		return PortalTypes.err(
			PortalTypes.ResultCode.StateConflict,
			"Portal launch attempt is no longer current.",
			serializePortal(portal)
		)
	end

	local validation = validateReadyToLaunch(player, portal)

	if not validation.ok then
		failPortal(portal, validation.message, validation)
		return validation
	end

	setPortalState(
		portal,
		PortalConfig.PortalStates.Transitioning,
		"CinematicTransitionStarted",
		nil
	)

	for index, cue in ipairs(portal.definition.cinematicSequence) do
		addTransitionHandle(
			portal,
			Scheduler.delay(
				(index - 1) * 0.15,
				function()
					if launchToken ~= nil and portal.launchToken ~= launchToken then
						return
					end

					fireAtmosphereCue(portal, cue, {
						sequenceIndex = index,
						total = #portal.definition.cinematicSequence,
					})
				end,
				"PortalCue:" .. portal.id .. ":" .. cue,
				"LobbyPortal",
				{
					"Portal",
					"Atmosphere",
				}
			)
		)
	end

	addTransitionHandle(
		portal,
		Scheduler.delay(1, function()
			if launchToken ~= nil and portal.launchToken ~= launchToken then
				return
			end

			if portal.state ~= PortalConfig.PortalStates.Transitioning then
				return
			end

			local leader = Players:GetPlayerByUserId(player.UserId)

			if leader == nil then
				failPortal(portal, "Party leader left before matchmaking launch.", nil)
				return
			end

			local launchValidation = validateReadyToLaunch(leader, portal)

			if not launchValidation.ok then
				failPortal(portal, launchValidation.message, launchValidation)
				return
			end

			setPortalState(
				portal,
				PortalConfig.PortalStates.Launching,
				"DelegatingToMatchmaking",
				nil
			)

			local launchResult = MatchmakingService.requestLaunch(leader)
			transitionHandles[portal.id] = nil

			if not launchResult.ok then
				failPortal(portal, launchResult.message, launchResult)
			end
		end, "PortalLaunch:" .. portal.id, "LobbyPortal", { "Portal", "Launch" })
	)

	return PortalTypes.ok("Portal transition started.", serializePortal(portal))
end

function PortalService.playerEnteredZone(player: Player, portalId: string): PortalResult
	return PortalService.boardPlayer(player, portalId)
end

function PortalService.playerExitedZone(player: Player, portalId: string): PortalResult
	return PortalService.exitPlayer(player, portalId, "ZoneExit")
end

function PortalService.registerPortalZone(portalId: string, zonePart: BasePart): (boolean, string?)
	local portal = getPortal(portalId)

	if portal == nil then
		return false, "Portal was not found."
	end

	registeredZoneCounts[portalId] = (registeredZoneCounts[portalId] or 0) + 1
	zoneContactCounts[portalId] = zoneContactCounts[portalId] or {}

	table.insert(
		zoneConnections,
		zonePart.Touched:Connect(function(hit)
			local player = getPlayerFromHit(hit)

			if player ~= nil then
				local contacts = zoneContactCounts[portalId]

				if contacts ~= nil then
					contacts[player.UserId] = (contacts[player.UserId] or 0) + 1
				end

				PortalService.playerEnteredZone(player, portalId)
			end
		end)
	)

	table.insert(
		zoneConnections,
		zonePart.TouchEnded:Connect(function(hit)
			local player = getPlayerFromHit(hit)

			if player ~= nil then
				local contacts = zoneContactCounts[portalId]

				if contacts ~= nil then
					contacts[player.UserId] = math.max(0, (contacts[player.UserId] or 0) - 1)

					if contacts[player.UserId] == 0 then
						contacts[player.UserId] = nil
						PortalService.playerExitedZone(player, portalId)
					end
				end
			end
		end)
	)

	return true, nil
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

	initializePortals()
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

	for _, connection in ipairs(zoneConnections) do
		connection:Disconnect()
	end

	for _, disconnect in ipairs(busDisconnects) do
		disconnect()
	end

	for _, handle in pairs(countdownHandles) do
		Scheduler.cancel(handle)
	end

	for _, handle in pairs(cooldownHandles) do
		Scheduler.cancel(handle)
	end

	for _, handles in pairs(transitionHandles) do
		for _, handle in ipairs(handles) do
			Scheduler.cancel(handle)
		end
	end

	table.clear(eventConnections)
	table.clear(zoneConnections)
	table.clear(busDisconnects)
	table.clear(countdownHandles)
	table.clear(cooldownHandles)
	table.clear(transitionHandles)
	table.clear(zoneContactCounts)
	table.clear(registeredZoneCounts)
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

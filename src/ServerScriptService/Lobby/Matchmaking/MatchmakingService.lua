--!strict
-- Launch validation and matchmaking orchestration for solo and party chapter entry.

local ServerScriptService = game:GetService("ServerScriptService")

local Core = ServerScriptService.Core
local EventBus = require(Core.EventBus)
local Logger = require(Core.Logger)
local Scheduler = require(Core.Scheduler)

local PartyConfig = require(ServerScriptService.Lobby.Parties.PartyConfig)
local PartyService = require(ServerScriptService.Lobby.Parties.PartyService)
local PartyTypes = require(ServerScriptService.Lobby.Parties.PartyTypes)
local QueueService = require(ServerScriptService.Lobby.Queues.QueueService)
local LobbyTeleportService = require(ServerScriptService.Lobby.Teleporting.TeleportService)

local MatchmakingService = {}

local log = Logger.scope("MatchmakingService")
local lastLaunchAttempt: { [string]: number } = {}

local function cooldownRemaining(partyId: string): number
	local lastAttempt = lastLaunchAttempt[partyId]

	if lastAttempt == nil then
		return 0
	end

	return math.max(0, PartyConfig.LaunchCooldownSeconds - (os.clock() - lastAttempt))
end

function MatchmakingService.requestLaunch(player: Player)
	local party = PartyService.getPartyForPlayer(player)

	if party == nil then
		local createResult = PartyService.createParty(player)

		if not createResult.ok then
			return createResult
		end

		party = PartyService.getPartyForPlayer(player)

		if party == nil then
			return PartyTypes.err(
				PartyTypes.ResultCode.InvalidRequest,
				"Could not create solo party."
			)
		end

		PartyService.setReady(player, true)
	end

	if party.leaderUserId ~= player.UserId then
		return PartyTypes.err(
			PartyTypes.ResultCode.NotLeader,
			"Only the party leader can launch.",
			PartyService.serializeParty(party)
		)
	end

	local remaining = cooldownRemaining(party.id)

	if remaining > 0 then
		return PartyTypes.err(
			PartyTypes.ResultCode.LaunchCooldown,
			"Launch is on cooldown.",
			PartyService.serializeParty(party),
			{
				remaining = remaining,
			}
		)
	end

	local validation = PartyService.validatePartyForLaunch(party)

	if not validation.ok then
		return validation
	end

	if QueueService.isQueued(party.id) then
		return PartyTypes.err(
			PartyTypes.ResultCode.LaunchInProgress,
			"Party is already queued.",
			PartyService.serializeParty(party)
		)
	end

	lastLaunchAttempt[party.id] = os.clock()
	PartyService.markLaunching(party.id, true)

	local queued, queueErr = QueueService.enqueue(party.id, party.selectedChapterId, player.UserId)

	if not queued then
		PartyService.markLaunching(party.id, false)
		return PartyTypes.err(
			PartyTypes.ResultCode.LaunchInProgress,
			queueErr or "Party is already queued.",
			PartyService.serializeParty(party)
		)
	end

	EventBus.publishDeferred("Lobby.LaunchRequested", {
		partyId = party.id,
		chapterId = party.selectedChapterId,
		leaderUserId = player.UserId,
	})

	Scheduler.defer(function()
		QueueService.setState(party.id, "Teleporting")
		local teleportResult = LobbyTeleportService.launchParty(party)

		if teleportResult.ok then
			QueueService.complete(party.id)
		else
			QueueService.fail(party.id, teleportResult.message)
			PartyService.markLaunching(party.id, false)
		end

		EventBus.publishDeferred("Lobby.LaunchCompleted", {
			partyId = party.id,
			result = teleportResult,
		})
	end, "LobbyLaunch:" .. party.id, "Lobby", { "Launch" })

	log.withContext("INFO", "Party launch queued", {
		partyId = party.id,
		chapterId = party.selectedChapterId,
	})

	return PartyTypes.ok("Party launch queued.", PartyService.serializeParty(party))
end

function MatchmakingService.inspect()
	return {
		lastLaunchAttempt = table.clone(lastLaunchAttempt),
		queue = QueueService.inspect(),
	}
end

function MatchmakingService.validate(): (boolean, string?)
	return QueueService.validate()
end

function MatchmakingService.runSelfChecks()
	local ok = true
	local details = {}

	local partyChecks = PartyService.runSelfChecks()
	details.party = partyChecks
	ok = ok and partyChecks.ok

	return {
		ok = ok,
		details = details,
	}
end

return MatchmakingService

--!strict
-- Safe teleport abstraction for future chapter server launch.

local TeleportServiceApi = game:GetService("TeleportService")

local ServerScriptService = game:GetService("ServerScriptService")

local Core = ServerScriptService.Core
local Logger = require(Core.Logger)

local PartyConfig = require(ServerScriptService.Lobby.Parties.PartyConfig)
local PartyTypes = require(ServerScriptService.Lobby.Parties.PartyTypes)

local TeleportService = {}

type Party = PartyTypes.Party

local log = Logger.scope("LobbyTeleportService")

local function getPlayersForParty(party: Party): { Player }
	local players = {}

	for _, userId in ipairs(party.memberOrder) do
		local player = game:GetService("Players"):GetPlayerByUserId(userId)

		if player ~= nil then
			table.insert(players, player)
		end
	end

	return players
end

function TeleportService.launchParty(party: Party)
	local chapter = PartyConfig.getChapter(party.selectedChapterId)

	if chapter == nil or chapter.enabled ~= true then
		return PartyTypes.err(
			PartyTypes.ResultCode.InvalidChapter,
			"Selected chapter is not available."
		)
	end

	if chapter.placeId == nil or chapter.placeId == 0 then
		log.withContext("WARN", "Teleport disabled because chapter place id is missing", {
			partyId = party.id,
			chapterId = party.selectedChapterId,
		})

		return PartyTypes.err(
			PartyTypes.ResultCode.TeleportDisabled,
			"Chapter teleport is not configured yet. The party is valid, but no place id is available."
		)
	end

	local players = getPlayersForParty(party)

	if #players == 0 then
		return PartyTypes.err(
			PartyTypes.ResultCode.InvalidRequest,
			"No online players are available to teleport."
		)
	end

	log.withContext("INFO", "Teleport attempt started", {
		partyId = party.id,
		chapterId = party.selectedChapterId,
		playerCount = #players,
		placeId = chapter.placeId,
		reservedServerEnabled = chapter.reservedServerEnabled,
	})

	local ok, err = pcall(function()
		if chapter.reservedServerEnabled then
			local accessCode = TeleportServiceApi:ReserveServer(chapter.placeId)
			TeleportServiceApi:TeleportToPrivateServer(chapter.placeId, accessCode, players)
		else
			TeleportServiceApi:TeleportAsync(chapter.placeId, players)
		end
	end)

	if not ok then
		log.withContext("ERROR", "Teleport attempt failed", {
			partyId = party.id,
			chapterId = party.selectedChapterId,
			error = tostring(err),
		})

		return PartyTypes.err(
			PartyTypes.ResultCode.TeleportFailed,
			"Teleport failed: " .. tostring(err)
		)
	end

	return PartyTypes.ok("Teleport started.")
end

function TeleportService.validate(): (boolean, string?)
	return true, nil
end

return TeleportService

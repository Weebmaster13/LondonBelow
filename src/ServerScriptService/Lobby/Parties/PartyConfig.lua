--!strict
-- Server party configuration. Keep authoritative limits here.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SharedLobbyConfig = require(ReplicatedStorage.Lobby.LobbyConfig.SharedLobbyConfig)

local PartyConfig = {}

PartyConfig.MaxPartySize = SharedLobbyConfig.MaxPartySize
PartyConfig.MinPartySize = SharedLobbyConfig.MinPartySize
PartyConfig.DefaultChapterId = SharedLobbyConfig.DefaultChapterId
PartyConfig.LaunchCooldownSeconds = 5
PartyConfig.RemoteRateLimitPerSecond = 8
PartyConfig.PartyIdPrefix = "LBP"
PartyConfig.Chapters = SharedLobbyConfig.Chapters

function PartyConfig.getChapter(chapterId: string)
	return PartyConfig.Chapters[chapterId]
end

function PartyConfig.isValidChapter(chapterId: string): boolean
	local chapter = PartyConfig.getChapter(chapterId)

	return chapter ~= nil and chapter.enabled == true
end

return PartyConfig

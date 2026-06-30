--!strict
-- Shared lobby configuration safe for both client and server.

local SharedLobbyConfig = {}

SharedLobbyConfig.MaxPartySize = 4
SharedLobbyConfig.MinPartySize = 1
SharedLobbyConfig.DefaultChapterId = "chapter_1"
SharedLobbyConfig.RemoteNamespace = "Lobby"

SharedLobbyConfig.Chapters = {
	chapter_1 = {
		id = "chapter_1",
		displayName = "Chapter 1: The House Below",
		enabled = true,
		minPlayers = 1,
		maxPlayers = 4,
		placeId = nil,
		reservedServerEnabled = false,
	},
}

SharedLobbyConfig.ClientDebug = {
	printStateUpdates = true,
	printErrors = true,
}

return SharedLobbyConfig

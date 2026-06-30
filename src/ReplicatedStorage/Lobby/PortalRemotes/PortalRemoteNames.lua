--!strict
-- Named Lobby Portal remotes. Keep portal networking explicit and versioned.

local PortalRemoteNames = {}

PortalRemoteNames.Namespace = "LobbyPortal"
PortalRemoteNames.Version = 1

PortalRemoteNames.ClientToServer = {
	RequestBoard = "RequestBoard",
	RequestExit = "RequestExit",
	RequestLaunch = "RequestLaunch",
	RequestState = "RequestState",
}

PortalRemoteNames.ServerToClient = {
	PortalStateUpdated = "PortalStateUpdated",
	PortalError = "PortalError",
	PortalAtmosphereCue = "PortalAtmosphereCue",
}

return PortalRemoteNames

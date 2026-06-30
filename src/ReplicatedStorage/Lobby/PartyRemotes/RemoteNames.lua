--!strict
-- Named Lobby remotes. Do not create vague remotes or bypass RemoteManager.

local RemoteNames = {}

RemoteNames.Namespace = "Lobby"
RemoteNames.Version = 1

RemoteNames.ClientToServer = {
	CreateParty = "CreateParty",
	JoinParty = "JoinParty",
	LeaveParty = "LeaveParty",
	KickMember = "KickMember",
	TransferLeader = "TransferLeader",
	SetReady = "SetReady",
	SelectChapter = "SelectChapter",
	SetLocked = "SetLocked",
	RequestLaunch = "RequestLaunch",
	RequestState = "RequestState",
}

RemoteNames.ServerToClient = {
	PartyStateUpdated = "PartyStateUpdated",
	LobbyError = "LobbyError",
	LaunchStateUpdated = "LaunchStateUpdated",
}

return RemoteNames

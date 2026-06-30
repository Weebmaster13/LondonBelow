--!strict
--[[
	Debug lobby client for Phase 2.

	This is not final UI. It provides a clean client boundary for requesting
	party actions and observing server-owned lobby state while final menus are
	designed later.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RemoteNames = require(ReplicatedStorage.Lobby.PartyRemotes.RemoteNames)
local SharedLobbyConfig = require(ReplicatedStorage.Lobby.LobbyConfig.SharedLobbyConfig)

local LobbyClient = {}

local remotesRoot = ReplicatedStorage:WaitForChild("Remotes")
local lobbyRemotes = remotesRoot:WaitForChild(RemoteNames.Namespace)

local function getRemote(name: string): RemoteEvent
	return lobbyRemotes:WaitForChild(
			string.format("%s_v%d", name, RemoteNames.Version)
		) :: RemoteEvent
end

local remotes = {
	createParty = getRemote(RemoteNames.ClientToServer.CreateParty),
	leaveParty = getRemote(RemoteNames.ClientToServer.LeaveParty),
	setReady = getRemote(RemoteNames.ClientToServer.SetReady),
	requestState = getRemote(RemoteNames.ClientToServer.RequestState),
	requestLaunch = getRemote(RemoteNames.ClientToServer.RequestLaunch),
	partyStateUpdated = getRemote(RemoteNames.ServerToClient.PartyStateUpdated),
	lobbyError = getRemote(RemoteNames.ServerToClient.LobbyError),
	launchStateUpdated = getRemote(RemoteNames.ServerToClient.LaunchStateUpdated),
}

local currentPartyState: any? = nil
local ready = false

function LobbyClient.requestCreateParty()
	remotes.createParty:FireServer({})
end

function LobbyClient.requestLeaveParty()
	remotes.leaveParty:FireServer({})
end

function LobbyClient.requestReadyToggle()
	ready = not ready
	remotes.setReady:FireServer({
		ready = ready,
	})
end

function LobbyClient.requestLaunch()
	remotes.requestLaunch:FireServer({})
end

function LobbyClient.requestState()
	remotes.requestState:FireServer({})
end

function LobbyClient.getCurrentPartyState()
	return currentPartyState
end

remotes.partyStateUpdated.OnClientEvent:Connect(function(payload)
	currentPartyState = payload.party

	if SharedLobbyConfig.ClientDebug.printStateUpdates then
		print("[LondonBelow][LobbyClient] Party state updated", payload)
	end
end)

remotes.lobbyError.OnClientEvent:Connect(function(payload)
	if SharedLobbyConfig.ClientDebug.printErrors then
		warn("[LondonBelow][LobbyClient] Lobby error", payload)
	end
end)

remotes.launchStateUpdated.OnClientEvent:Connect(function(payload)
	print("[LondonBelow][LobbyClient] Launch state updated", payload)
end)

task.defer(function()
	LobbyClient.requestState()
end)

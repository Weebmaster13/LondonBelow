--!strict
--[[
	Debug portal client for Phase 2.5.

	This is not final UI. It listens to server-owned portal state and exposes
	clean request functions for future board prompts, countdown UI, transitions,
	and cinematic lobby effects.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PortalRemoteNames = require(ReplicatedStorage.Lobby.PortalRemotes.PortalRemoteNames)
local SharedPortalConfig = require(ReplicatedStorage.Lobby.LobbyConfig.SharedPortalConfig)

local PortalClient = {}
local remoteWaitTimeout = SharedPortalConfig.ClientDebug.remoteWaitTimeoutSeconds or 15

local function waitForChildWithTimeout(parent: Instance, childName: string): Instance
	local child = parent:WaitForChild(childName, remoteWaitTimeout)

	if child == nil then
		error(
			string.format(
				"[LondonBelow][PortalClient] Timed out waiting for %s.%s after %d seconds",
				parent:GetFullName(),
				childName,
				remoteWaitTimeout
			),
			2
		)
	end

	return child
end

local remotesRoot = waitForChildWithTimeout(ReplicatedStorage, "Remotes")
local portalRemotes = waitForChildWithTimeout(remotesRoot, PortalRemoteNames.Namespace)

local function getRemote(name: string): RemoteEvent
	local remoteName = string.format("%s_v%d", name, PortalRemoteNames.Version)
	local remote = waitForChildWithTimeout(portalRemotes, remoteName)

	if not remote:IsA("RemoteEvent") then
		error(
			string.format(
				"[LondonBelow][PortalClient] %s is not a RemoteEvent",
				remote:GetFullName()
			),
			2
		)
	end

	return remote :: RemoteEvent
end

local remotes = {
	requestBoard = getRemote(PortalRemoteNames.ClientToServer.RequestBoard),
	requestExit = getRemote(PortalRemoteNames.ClientToServer.RequestExit),
	requestLaunch = getRemote(PortalRemoteNames.ClientToServer.RequestLaunch),
	requestState = getRemote(PortalRemoteNames.ClientToServer.RequestState),
	portalStateUpdated = getRemote(PortalRemoteNames.ServerToClient.PortalStateUpdated),
	portalError = getRemote(PortalRemoteNames.ServerToClient.PortalError),
	portalAtmosphereCue = getRemote(PortalRemoteNames.ServerToClient.PortalAtmosphereCue),
}

local latestPortalState: any? = nil
local latestPortalStates: any? = nil

function PortalClient.requestBoard(portalId: string?)
	remotes.requestBoard:FireServer({
		portalId = portalId or SharedPortalConfig.DefaultPortalId,
	})
end

function PortalClient.requestExit(portalId: string?)
	remotes.requestExit:FireServer({
		portalId = portalId or SharedPortalConfig.DefaultPortalId,
	})
end

function PortalClient.requestLaunch(portalId: string?)
	remotes.requestLaunch:FireServer({
		portalId = portalId or SharedPortalConfig.DefaultPortalId,
	})
end

function PortalClient.requestState()
	remotes.requestState:FireServer({})
end

function PortalClient.getLatestPortalState()
	return latestPortalState
end

function PortalClient.getLatestPortalStates()
	return latestPortalStates
end

remotes.portalStateUpdated.OnClientEvent:Connect(function(payload)
	if payload.portal ~= nil then
		latestPortalState = payload.portal
	end

	if payload.portals ~= nil then
		latestPortalStates = payload.portals
	end

	if SharedPortalConfig.ClientDebug.printStateUpdates then
		print("[LondonBelow][PortalClient] Portal state updated", payload)
	end
end)

remotes.portalError.OnClientEvent:Connect(function(payload)
	if SharedPortalConfig.ClientDebug.printErrors then
		warn("[LondonBelow][PortalClient] Portal error", payload)
	end
end)

remotes.portalAtmosphereCue.OnClientEvent:Connect(function(payload)
	if SharedPortalConfig.ClientDebug.printAtmosphereCues then
		print("[LondonBelow][PortalClient] Atmosphere cue", payload)
	end
end)

task.defer(function()
	PortalClient.requestState()
end)

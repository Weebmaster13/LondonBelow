--!strict
--[[
	Client networking adapter for Player Experience.

	Owns waiting for server-defined remotes, firing client requests, and exposing
	server updates to presentation modules. It does not create remotes or own
	gameplay truth.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RemoteNames = require(ReplicatedStorage.Shared.PlayerExperienceRemoteNames)

local PlayerExperienceNetwork = {}

local REMOTE_TIMEOUT_SECONDS = 15
local remotes: { [string]: RemoteEvent } = {}

local function waitForChild(parent: Instance, name: string): Instance?
	local child = parent:WaitForChild(name, REMOTE_TIMEOUT_SECONDS)

	if child == nil then
		warn("[LondonBelow][PlayerExperience] Timed out waiting for " .. name)
	end

	return child
end

local function remoteName(name: string): string
	return string.format("%s_v%d", name, RemoteNames.Version)
end

function PlayerExperienceNetwork.initialize(): boolean
	local root = waitForChild(ReplicatedStorage, "Remotes")

	if root == nil then
		return false
	end

	local namespace = waitForChild(root, RemoteNames.Namespace)

	if namespace == nil then
		return false
	end

	for _, name in pairs(RemoteNames.ClientToServer) do
		local remote = waitForChild(namespace, remoteName(name))

		if remote == nil or not remote:IsA("RemoteEvent") then
			return false
		end

		remotes[name] = remote
	end

	for _, name in pairs(RemoteNames.ServerToClient) do
		local remote = waitForChild(namespace, remoteName(name))

		if remote == nil or not remote:IsA("RemoteEvent") then
			return false
		end

		remotes[name] = remote
	end

	return true
end

function PlayerExperienceNetwork.fire(name: string, payload: any)
	local remote = remotes[name]

	if remote == nil then
		warn("[LondonBelow][PlayerExperience] Remote unavailable: " .. name)
		return
	end

	remote:FireServer(payload)
end

function PlayerExperienceNetwork.on(name: string, callback: (any) -> ())
	local remote = remotes[name]

	if remote == nil then
		warn("[LondonBelow][PlayerExperience] Remote unavailable: " .. name)
		return nil
	end

	return remote.OnClientEvent:Connect(callback)
end

function PlayerExperienceNetwork.names()
	return RemoteNames
end

return PlayerExperienceNetwork

--!strict

local CollectionService = game:GetService("CollectionService")
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")
local SoundService = game:GetService("SoundService")
local Workspace = game:GetService("Workspace")

local RuntimeCapture = {}

local function countCoordinators(root: Instance): (number, { string })
	local names = {}
	for _, descendant in ipairs(root:GetDescendants()) do
		if
			descendant:IsA("ModuleScript")
			and string.find(descendant.Name, "Coordinator") ~= nil
		then
			table.insert(names, descendant:GetFullName())
		end
	end
	table.sort(names)
	return #names, names
end

function RuntimeCapture.observe(): any
	local coordinatorCount, coordinatorNames = countCoordinators(ServerScriptService)
	return {
		runService = {
			isStudio = RunService:IsStudio(),
			isServer = RunService:IsServer(),
			isClient = RunService:IsClient(),
			isRunning = RunService:IsRunning(),
		},
		gameLoaded = game.Loaded,
		services = {
			Players = Players ~= nil,
			Workspace = Workspace ~= nil,
			ReplicatedStorage = ReplicatedStorage ~= nil,
			ServerScriptService = ServerScriptService ~= nil,
			Lighting = Lighting ~= nil,
			SoundService = SoundService ~= nil,
			CollectionService = CollectionService ~= nil,
		},
		players = {
			count = #Players:GetPlayers(),
		},
		workspace = {
			name = Workspace.Name,
			childCount = #Workspace:GetChildren(),
		},
		coordinators = {
			count = coordinatorCount,
			names = coordinatorNames,
		},
	}
end

return RuntimeCapture

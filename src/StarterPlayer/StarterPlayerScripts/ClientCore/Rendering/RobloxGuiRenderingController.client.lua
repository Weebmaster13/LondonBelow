--!strict

local Players = game:GetService("Players")

local Runtime = require(script.Parent.RobloxGuiRenderingRuntime)

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local result = Runtime.configure(playerGui)
if not result.ok then
	warn("[LondonEngine][RobloxGuiRendering] configuration failed", result.code)
end

local playerGuiConnection = player.ChildAdded:Connect(function(child)
	if child:IsA("PlayerGui") and child ~= playerGui then
		playerGui = child
		local remountResult = Runtime.remount(child)
		if not remountResult.ok then
			warn("[LondonEngine][RobloxGuiRendering] remount failed", remountResult.code)
		end
	end
end)

script.Destroying:Connect(function()
	playerGuiConnection:Disconnect()
	Runtime.shutdown()
end)

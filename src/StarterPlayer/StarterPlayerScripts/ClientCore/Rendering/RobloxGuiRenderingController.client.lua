--!strict

local Players = game:GetService("Players")

local Runtime = require(script.Parent.RobloxGuiRenderingRuntime)

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local result = Runtime.configure(playerGui)
if not result.ok then
	warn("[LondonEngine][RobloxGuiRendering] configuration failed", result.code)
end

script.Destroying:Connect(function()
	Runtime.shutdown()
end)

--!strict

local Players = game:GetService("Players")
local GuiService = game:GetService("GuiService")

local Runtime = require(script.Parent.RobloxGuiRenderingRuntime)

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local result = Runtime.configure(playerGui)
if not result.ok then
	warn("[LondonEngine][RobloxGuiRendering] configuration failed", result.code)
end

local viewportConnection = nil :: RBXScriptConnection?
local function refreshResponsiveContext()
	local camera = workspace.CurrentCamera
	if not camera then
		return
	end
	local topLeft, bottomRight = GuiService:GetGuiInset()
	local contextResult = Runtime.setResponsiveContext(camera.ViewportSize, {
		left = topLeft.X,
		top = topLeft.Y,
		right = bottomRight.X,
		bottom = bottomRight.Y,
	})
	if not contextResult.ok then
		warn("[LondonEngine][RobloxGuiRendering] responsive context failed", contextResult.code)
	end
end

local function bindCamera()
	if viewportConnection then
		viewportConnection:Disconnect()
		viewportConnection = nil
	end
	local camera = workspace.CurrentCamera
	if camera then
		viewportConnection = camera:GetPropertyChangedSignal("ViewportSize"):Connect(refreshResponsiveContext)
		refreshResponsiveContext()
	end
end

bindCamera()
local cameraConnection = workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(bindCamera)

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
	cameraConnection:Disconnect()
	if viewportConnection then
		viewportConnection:Disconnect()
	end
	Runtime.shutdown()
end)

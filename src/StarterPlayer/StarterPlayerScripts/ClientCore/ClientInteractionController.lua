--!strict
--[[
	Client-side interaction presenter/requester.

	Owns camera raycast focus requests, prompt updates, and interaction request
	payloads. It does not decide whether an interaction succeeds.
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local ClientInteractionController = {}

type Network = {
	fire: (string, any) -> (),
	on: (string, (any) -> ()) -> RBXScriptConnection?,
	names: () -> any,
}

local localPlayer = Players.LocalPlayer
local network: Network? = nil
local promptController: any = nil
local currentTarget: Instance? = nil
local currentFocus: any? = nil
local focusConnection: RBXScriptConnection? = nil
local focusAccumulator = 0

local function cameraRaycast(): Instance?
	local camera = workspace.CurrentCamera

	if camera == nil then
		return nil
	end

	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude

	if localPlayer.Character ~= nil then
		params.FilterDescendantsInstances = { localPlayer.Character }
	end

	local result = workspace:Raycast(camera.CFrame.Position, camera.CFrame.LookVector * 18, params)

	if result == nil then
		return nil
	end

	return result.Instance
end

local function names()
	return (network :: Network).names()
end

local function requestFocus(target: Instance?)
	if network == nil then
		return
	end

	if target == nil then
		if currentFocus ~= nil and promptController ~= nil then
			currentFocus = nil
			promptController.updateFocus(nil)
		end

		return
	end

	(network :: Network).fire(names().ClientToServer.RequestFocus, {
		target = target,
	})
end

function ClientInteractionController.initialize(networkAdapter: Network, prompt: any)
	network = networkAdapter
	promptController = prompt

	networkAdapter.on(names().ServerToClient.FocusUpdated, function(payload)
		currentFocus = payload

		if promptController ~= nil then
			promptController.updateFocus(payload)
		end
	end)

	networkAdapter.on(names().ServerToClient.InteractionResult, function(payload)
		if type(payload) == "table" and not payload.ok then
			warn("[LondonBelow][Interaction] Request rejected", payload.code, payload.message)
		end
	end)

	focusConnection = RunService.RenderStepped:Connect(function(deltaTime)
		focusAccumulator += deltaTime

		if focusAccumulator < 0.08 then
			return
		end

		focusAccumulator = 0
		currentTarget = cameraRaycast()
		requestFocus(currentTarget)
	end)
end

function ClientInteractionController.requestInteraction()
	if network == nil or currentFocus == nil or currentFocus.interactionId == nil then
		return
	end

	(network :: Network).fire(names().ClientToServer.RequestInteraction, {
		interactionId = currentFocus.interactionId,
		target = currentTarget,
		clientFocusId = currentFocus.interactionId,
		inputKind = "Primary",
		requestId = tostring(os.clock()),
	})
end

function ClientInteractionController.shutdown()
	if focusConnection ~= nil then
		focusConnection:Disconnect()
		focusConnection = nil
	end

	network = nil
	promptController = nil
	currentTarget = nil
	currentFocus = nil
end

return ClientInteractionController

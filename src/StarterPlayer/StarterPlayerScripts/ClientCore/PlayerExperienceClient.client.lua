--!strict
--[[
	Client bootstrap for the Player Experience Foundation.

	Owns local composition of networking, input, camera, prompts, focus raycasts,
	and presentation feedback. It never owns authoritative gameplay state.
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local localPlayer = Players.LocalPlayer
local Network = require(script.Parent.Networking.PlayerExperienceNetwork)
local InputController = require(script.Parent.Input.PlayerInputController)
local CameraController = require(script.Parent.Camera.FirstPersonCameraController)
local FeedbackController = require(script.Parent.Effects.FeedbackController)
local PromptController = require(script.Parent.Parent.ClientUI.HUD.InteractionPromptController)

local initialized = Network.initialize()

if not initialized then
	warn("[LondonBelow][PlayerExperience] Client disabled because remotes were unavailable.")
	return
end

local names = Network.names()
local currentTarget: Instance? = nil
local currentFocus: any? = nil
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

local function requestFocus(target: Instance?)
	if target == nil then
		if currentFocus ~= nil then
			currentFocus = nil
			PromptController.updateFocus(nil)
		end

		return
	end

	Network.fire(names.ClientToServer.RequestFocus, {
		target = target,
	})
end

local function requestInteraction()
	if currentFocus == nil or currentFocus.interactionId == nil then
		return
	end

	Network.fire(names.ClientToServer.RequestInteraction, {
		interactionId = currentFocus.interactionId,
		target = currentTarget,
		clientFocusId = currentFocus.interactionId,
		inputKind = "Primary",
		requestId = tostring(os.clock()),
	})
end

Network.on(names.ServerToClient.FocusUpdated, function(payload)
	currentFocus = payload
	PromptController.updateFocus(payload)
end)

Network.on(names.ServerToClient.InteractionResult, function(payload)
	if type(payload) ~= "table" then
		return
	end

	if not payload.ok then
		warn("[LondonBelow][PlayerExperience] Interaction rejected", payload.code, payload.message)
	end
end)

Network.on(names.ServerToClient.Feedback, FeedbackController.play)
Network.on(names.ServerToClient.MovementProfileUpdated, CameraController.applyProfile)

PromptController.initialize()
CameraController.initialize()
InputController.initialize(Network, requestInteraction)

RunService.RenderStepped:Connect(function(deltaTime)
	focusAccumulator += deltaTime

	if focusAccumulator < 0.08 then
		return
	end

	focusAccumulator = 0
	currentTarget = cameraRaycast()
	requestFocus(currentTarget)
end)

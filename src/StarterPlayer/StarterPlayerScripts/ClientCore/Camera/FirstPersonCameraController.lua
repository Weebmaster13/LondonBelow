--!strict
--[[
	Smooth first-person camera foundation.

	Owns local camera mode, mouse capture, configurable sensitivity, and reduced
	motion support. It does not create scares, force horror effects, or own
	server truth.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local PlayerExperienceConfig = require(ReplicatedStorage.Config.PlayerExperienceConfig)

local FirstPersonCameraController = {}

local localPlayer = Players.LocalPlayer
local connection: RBXScriptConnection? = nil
local inputConnection: RBXScriptConnection? = nil
local yaw = 0
local pitch = 0
local cameraConfig = PlayerExperienceConfig.Camera
local accessibility = PlayerExperienceConfig.Accessibility

local function characterHead(): BasePart?
	local character = localPlayer.Character

	if character == nil then
		return nil
	end

	return character:FindFirstChild("Head") :: BasePart?
end

function FirstPersonCameraController.applyProfile(payload: any)
	if type(payload) ~= "table" then
		return
	end

	if type(payload.camera) == "table" then
		cameraConfig = payload.camera
	end

	if type(payload.accessibility) == "table" then
		accessibility = payload.accessibility
	end
end

function FirstPersonCameraController.initialize()
	local camera = workspace.CurrentCamera

	if camera == nil then
		return
	end

	camera.CameraType = Enum.CameraType.Scriptable
	UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
	UserInputService.MouseIconEnabled = false

	inputConnection = UserInputService.InputChanged:Connect(function(input)
		if input.UserInputType ~= Enum.UserInputType.MouseMovement then
			return
		end

		local sensitivity = cameraConfig.mouseSensitivity
		yaw -= input.Delta.X * sensitivity
		pitch = math.clamp(
			pitch - input.Delta.Y * sensitivity,
			cameraConfig.minPitch,
			cameraConfig.maxPitch
		)
	end)

	connection = RunService.RenderStepped:Connect(function()
		local head = characterHead()
		local activeCamera = workspace.CurrentCamera

		if head == nil or activeCamera == nil then
			return
		end

		local smoothing = if accessibility.reducedMotion
			then cameraConfig.reducedMotionSmoothing
			else cameraConfig.smoothing
		local desired = CFrame.new(head.Position)
			* CFrame.Angles(0, math.rad(yaw), 0)
			* CFrame.Angles(math.rad(pitch), 0, 0)

		activeCamera.CFrame = activeCamera.CFrame:Lerp(desired, math.clamp(smoothing, 0.02, 1))
	end)
end

function FirstPersonCameraController.shutdown()
	if connection ~= nil then
		connection:Disconnect()
		connection = nil
	end

	if inputConnection ~= nil then
		inputConnection:Disconnect()
		inputConnection = nil
	end

	UserInputService.MouseBehavior = Enum.MouseBehavior.Default
	UserInputService.MouseIconEnabled = true
end

return FirstPersonCameraController

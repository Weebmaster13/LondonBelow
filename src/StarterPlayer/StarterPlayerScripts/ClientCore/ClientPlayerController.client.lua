--!strict
--[[
	Client bootstrap for the London Engine Player Presentation Runtime.

	Composes input, camera, interaction prompts, feedback hooks, and
	accessibility settings. It sends requests only; the server owns truth.
]]

local Network = require(script.Parent.Networking.PlayerExperienceNetwork)
local InputController = require(script.Parent.ClientInputController)
local CameraController = require(script.Parent.ClientCameraController)
local InteractionController = require(script.Parent.ClientInteractionController)
local PromptController = require(script.Parent.ClientPromptController)
local FeedbackController = require(script.Parent.ClientAudioFeedbackController)
local AccessibilityController = require(script.Parent.ClientAccessibilityController)

local initialized = Network.initialize()

if not initialized then
	warn("[LondonBelow][PlayerRuntime] Client disabled because remotes were unavailable.")
	return
end

local names = Network.names()

Network.on(names.ServerToClient.Feedback, FeedbackController.play)
Network.on(names.ServerToClient.MovementProfileUpdated, function(payload)
	CameraController.applyProfile(payload)

	if type(payload) == "table" then
		AccessibilityController.apply(payload.accessibility)
	end
end)

PromptController.initialize()
CameraController.initialize()
InteractionController.initialize(Network, PromptController)
InputController.initialize(Network, InteractionController.requestInteraction)

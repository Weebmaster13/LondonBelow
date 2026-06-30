--!strict
--[[
	Server interaction runtime configuration.

	Shared tuning lives in ReplicatedStorage. Server-only interaction limits and
	state defaults are declared here.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SharedConfig = require(ReplicatedStorage.Config.PlayerExperienceConfig)

local InteractionConfig = {}

InteractionConfig.RemoteRateLimitPerSecond = SharedConfig.RemoteRateLimitPerSecond
InteractionConfig.DefaultMaxDistance = SharedConfig.Interaction.defaultMaxDistance
InteractionConfig.RaycastPadding = SharedConfig.Interaction.raycastPadding
InteractionConfig.MaxInteractionIdLength = SharedConfig.Interaction.maxInteractionIdLength
InteractionConfig.DefaultPrompt = SharedConfig.Interaction.defaultPrompt
InteractionConfig.DefaultCooldownSeconds = 0.25
InteractionConfig.HoldProgressObservationStep = 0.25

return InteractionConfig

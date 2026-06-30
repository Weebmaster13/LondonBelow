--!strict
--[[
	Shared tuning for reusable player experience systems.

	Values here are intentionally chapter-agnostic. Future chapters may layer
	local profiles on top, but they should not rewrite movement, interaction,
	camera, or feedback rules.
]]

local PlayerExperienceConfig = {}

PlayerExperienceConfig.RemoteNamespace = "PlayerExperience"
PlayerExperienceConfig.RemoteVersion = 1
PlayerExperienceConfig.RemoteRateLimitPerSecond = 12

PlayerExperienceConfig.DefaultMovementProfile = {
	id = "default_first_person",
	walkSpeed = 12,
	sprintSpeed = 18,
	crouchSpeed = 7,
	jumpPower = 42,
	allowSprint = true,
	allowCrouch = true,
	allowJump = true,
	staminaEnabled = false,
	cameraHeight = 1.55,
	crouchCameraHeight = 1.05,
}

PlayerExperienceConfig.Interaction = {
	defaultMaxDistance = 12,
	focusRefreshSeconds = 0.08,
	raycastPadding = 0.25,
	maxMetadataKeys = 24,
	maxInteractionIdLength = 80,
	defaultPrompt = "Interact",
}

PlayerExperienceConfig.Camera = {
	mouseSensitivity = 0.18,
	controllerSensitivity = 0.12,
	minPitch = -78,
	maxPitch = 78,
	smoothing = 0.16,
	reducedMotionSmoothing = 0.04,
	headBobIntensity = 0.04,
	reducedMotionHeadBobIntensity = 0,
}

PlayerExperienceConfig.Accessibility = {
	reducedMotion = false,
	cameraShakeScale = 1,
	hapticsEnabled = true,
	promptHoldSeconds = 0,
}

return PlayerExperienceConfig

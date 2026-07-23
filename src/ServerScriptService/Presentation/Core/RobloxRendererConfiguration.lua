--!strict

local Serialization = require(script.Parent.PresentationSerialization)
local Types = require(script.Parent.PresentationTypes)

local Configuration = {}

local function defaultFlags()
	return {
		SupportsDialogue = true,
		SupportsHUD = true,
		SupportsNotifications = true,
		SupportsMenus = true,
		SupportsCaptions = true,
		SupportsPortraits = true,
		SupportsCameraPlanning = true,
		SupportsAnimationPlanning = true,
		SupportsAudioPlanning = true,
		SupportsAccessibilityMetadata = true,
		SupportsLocalizationMetadata = true,
	}
end

function Configuration.build(input: any)
	local config = input or {}
	return {
		MaximumSessions = config.MaximumSessions or 160,
		MaximumDescriptors = config.MaximumDescriptors or 320,
		MaximumQueueDepth = config.MaximumQueueDepth or 240,
		MaximumAcknowledgements = config.MaximumAcknowledgements or 520,
		MaximumSynchronizationRecords = config.MaximumSynchronizationRecords or 520,
		MaximumSnapshotSize = config.MaximumSnapshotSize
			or Types.RobloxRenderingLimits.MaxSnapshots,
		FeatureFlags = Serialization.deepCopy(config.FeatureFlags or defaultFlags()),
		RuntimePriority = config.RuntimePriority or 100,
	}
end

return Configuration

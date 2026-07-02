--!strict
-- Shared constants for Phase 32 Accessibility Runtime Foundation.

local Types = {}

Types.Mode = "ServerAuthoritativeAccessibilitySchemaRuntime"

Types.SchemaType = {
	AccessibilitySettingsSchema = "AccessibilitySettingsSchema",
	AccessibilityVisualSchema = "AccessibilityVisualSchema",
	AccessibilityAudioSchema = "AccessibilityAudioSchema",
	AccessibilityInputSchema = "AccessibilityInputSchema",
	AccessibilityMotionSchema = "AccessibilityMotionSchema",
	AccessibilityReadabilitySchema = "AccessibilityReadabilitySchema",
	AccessibilityContentWarningSchema = "AccessibilityContentWarningSchema",
	SystemAccessibilitySchema = "SystemAccessibilitySchema",
}

Types.ResultCode = {
	Ok = "Ok",
	InvalidRequest = "InvalidRequest",
	DuplicateSetting = "DuplicateSetting",
	DuplicateVisual = "DuplicateVisual",
	DuplicateAudio = "DuplicateAudio",
	DuplicateInput = "DuplicateInput",
	DuplicateMotion = "DuplicateMotion",
	DuplicateReadability = "DuplicateReadability",
	DuplicateContentWarning = "DuplicateContentWarning",
	UnsafePayload = "UnsafePayload",
}

Types.Limits = {
	MaxSettings = 700,
	MaxVisuals = 900,
	MaxAudios = 700,
	MaxInputs = 700,
	MaxMotions = 700,
	MaxReadabilities = 700,
	MaxContentWarnings = 700,
	MaxValidationFailures = 220,
	MaxSnapshotHistory = 80,
	MaxPayloadDepth = 9,
	MaxPayloadNodes = 360,
	MaxPayloadStringLength = 640,
	MaxTags = 32,
}

return Types

--!strict
-- Shared constants for Phase 35 Localization Runtime Foundation.

local Types = {}

Types.Mode = "ServerAuthoritativeLocalizationSchemaRuntime"

Types.SchemaType = {
	LocalizationLanguageSchema = "LocalizationLanguageSchema",
	LocalizationTextKeySchema = "LocalizationTextKeySchema",
	LocalizationPackageSchema = "LocalizationPackageSchema",
	LocalizationFallbackSchema = "LocalizationFallbackSchema",
	LocalizationSubtitleSchema = "LocalizationSubtitleSchema",
	LocalizationCaptionSchema = "LocalizationCaptionSchema",
	LocalizationTextSafetySchema = "LocalizationTextSafetySchema",
	SystemLocalizationSchema = "SystemLocalizationSchema",
}

Types.ResultCode = {
	Ok = "Ok",
	InvalidRequest = "InvalidRequest",
	DuplicateLanguage = "DuplicateLanguage",
	DuplicateTextKey = "DuplicateTextKey",
	DuplicatePackage = "DuplicatePackage",
	DuplicateFallback = "DuplicateFallback",
	DuplicateSubtitle = "DuplicateSubtitle",
	DuplicateCaption = "DuplicateCaption",
	DuplicateTextSafety = "DuplicateTextSafety",
	UnsafePayload = "UnsafePayload",
}

Types.Limits = {
	MaxLanguages = 500,
	MaxTextKeys = 2000,
	MaxPackages = 700,
	MaxFallbacks = 700,
	MaxSubtitles = 900,
	MaxCaptions = 900,
	MaxTextSafetyRules = 700,
	MaxValidationFailures = 220,
	MaxSnapshotHistory = 80,
	MaxPayloadDepth = 9,
	MaxPayloadNodes = 360,
	MaxPayloadStringLength = 640,
	MaxTags = 32,
}

return Types

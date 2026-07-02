--!strict
-- EventBus signal names emitted by Localization Runtime.

local Signals = {
	LanguageRegistered = "Localization.LanguageRegistered",
	TextKeyRegistered = "Localization.TextKeyRegistered",
	PackageRegistered = "Localization.PackageRegistered",
	FallbackRegistered = "Localization.FallbackRegistered",
	SubtitleRegistered = "Localization.SubtitleRegistered",
	CaptionRegistered = "Localization.CaptionRegistered",
	TextSafetyRegistered = "Localization.TextSafetyRegistered",
	ValidationFailed = "Localization.ValidationFailed",
	SnapshotCaptured = "Localization.SnapshotCaptured",
}

return Signals

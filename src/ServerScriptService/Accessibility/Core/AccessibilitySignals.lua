--!strict
-- Event names emitted by Accessibility Runtime Foundation.

local Signals = {
	SettingRegistered = "accessibilityRuntime.SettingRegistered",
	VisualRegistered = "accessibilityRuntime.VisualRegistered",
	AudioRegistered = "accessibilityRuntime.AudioRegistered",
	InputRegistered = "accessibilityRuntime.InputRegistered",
	MotionRegistered = "accessibilityRuntime.MotionRegistered",
	ReadabilityRegistered = "accessibilityRuntime.ReadabilityRegistered",
	ContentWarningRegistered = "accessibilityRuntime.ContentWarningRegistered",
	ValidationFailed = "accessibilityRuntime.ValidationFailed",
	SnapshotCaptured = "accessibilityRuntime.SnapshotCaptured",
}

return Signals

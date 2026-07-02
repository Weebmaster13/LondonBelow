--!strict
-- Event names emitted by Session Runtime Foundation.

local Signals = {
	SessionRegistered = "Session.SessionRegistered",
	PlayerSessionRegistered = "Session.PlayerSessionRegistered",
	PartyRegistered = "Session.PartyRegistered",
	ReadinessRecorded = "Session.ReadinessRecorded",
	LifecycleRecorded = "Session.LifecycleRecorded",
	JoinLeaveRecorded = "Session.JoinLeaveRecorded",
	ValidationFailed = "Session.ValidationFailed",
	SnapshotCaptured = "Session.SnapshotCaptured",
}

return Signals

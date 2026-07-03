--!strict
-- EventBus signal names emitted by Runtime Lifecycle.

local Signals = {
	StateRegistered = "RuntimeLifecycle.StateRegistered",
	TransitionRegistered = "RuntimeLifecycle.TransitionRegistered",
	PolicyRegistered = "RuntimeLifecycle.PolicyRegistered",
	GuardRegistered = "RuntimeLifecycle.GuardRegistered",
	EventRegistered = "RuntimeLifecycle.EventRegistered",
	FailureRegistered = "RuntimeLifecycle.FailureRegistered",
	RecoveryRegistered = "RuntimeLifecycle.RecoveryRegistered",
	CheckpointRegistered = "RuntimeLifecycle.CheckpointRegistered",
	AuditRegistered = "RuntimeLifecycle.AuditRegistered",
	CompatibilityRegistered = "RuntimeLifecycle.CompatibilityRegistered",
	ValidationFailed = "RuntimeLifecycle.ValidationFailed",
	SnapshotCaptured = "RuntimeLifecycle.SnapshotCaptured",
}

return Signals

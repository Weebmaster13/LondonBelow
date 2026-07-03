--!strict
-- Signal names for schema-only Runtime Scheduler diagnostics.

local Signals = {
	Registered = "RuntimeScheduler.Registered",
	Rejected = "RuntimeScheduler.Rejected",
	SnapshotCaptured = "RuntimeScheduler.SnapshotCaptured",
	SelfChecksCompleted = "RuntimeScheduler.SelfChecksCompleted",
	Shutdown = "RuntimeScheduler.Shutdown",
}

return Signals

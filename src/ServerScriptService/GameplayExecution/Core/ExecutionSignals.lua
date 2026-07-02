--!strict
-- Server-only EventBus signal names for Phase 20 execution gateway state.

local Signals = {}

Signals.RequestAccepted = "GameplayExecution.RequestAccepted"
Signals.RequestRejected = "GameplayExecution.RequestRejected"
Signals.RequestExpired = "GameplayExecution.RequestExpired"
Signals.RequestScheduled = "GameplayExecution.RequestScheduled"
Signals.DryRunRecorded = "GameplayExecution.DryRunRecorded"
Signals.ValidationFailed = "GameplayExecution.ValidationFailed"
Signals.SnapshotCaptured = "GameplayExecution.SnapshotCaptured"

return Signals

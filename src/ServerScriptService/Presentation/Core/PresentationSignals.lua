--!strict
-- Server-only EventBus signals for Presentation Runtime Foundation.

local Signals = {}

Signals.RequestRecorded = "Presentation.RequestRecorded"
Signals.RequestRejected = "Presentation.RequestRejected"
Signals.RequestQueued = "Presentation.RequestQueued"
Signals.RequestRouted = "Presentation.RequestRouted"
Signals.ValidationFailed = "Presentation.ValidationFailed"
Signals.SnapshotCaptured = "Presentation.SnapshotCaptured"

return Signals

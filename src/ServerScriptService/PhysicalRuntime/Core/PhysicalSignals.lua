--!strict
-- Server-only EventBus signals for Physical Runtime Foundation.

local Signals = {}

Signals.ObjectRegistered = "Physical.ObjectRegistered"
Signals.ObjectRemoved = "Physical.ObjectRemoved"
Signals.ReservationCreated = "Physical.ReservationCreated"
Signals.ReservationReleased = "Physical.ReservationReleased"
Signals.StateChanged = "Physical.StateChanged"
Signals.ValidationFailed = "Physical.ValidationFailed"
Signals.SnapshotCaptured = "Physical.SnapshotCaptured"

return Signals

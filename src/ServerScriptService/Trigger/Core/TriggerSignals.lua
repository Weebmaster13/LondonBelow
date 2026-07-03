--!strict
-- Reserved symbolic signal names for future Trigger schema observers.

local Signals = {}

Signals.SchemaRegistered = "Trigger.SchemaRegistered"
Signals.SchemaRejected = "Trigger.SchemaRejected"
Signals.SnapshotCaptured = "Trigger.SnapshotCaptured"

return Signals

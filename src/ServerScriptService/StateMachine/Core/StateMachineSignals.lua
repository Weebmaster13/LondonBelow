--!strict
-- Reserved symbolic signal names for future State Machine schema observers.

local Signals = {}

Signals.SchemaRegistered = "StateMachine.SchemaRegistered"
Signals.SchemaRejected = "StateMachine.SchemaRejected"
Signals.SnapshotCaptured = "StateMachine.SnapshotCaptured"

return Signals

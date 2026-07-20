--!strict
-- Server-only EventBus signals for Interaction Runtime Foundation.

local Signals = {}

Signals.InteractionRegistered = "Interaction.ObjectRegistered"
Signals.TargetRegistered = "Interaction.TargetRegistered"
Signals.IntentRecorded = "Interaction.IntentRecorded"
Signals.LockRecorded = "Interaction.LockRecorded"
Signals.CooldownRecorded = "Interaction.CooldownRecorded"
Signals.RequestEvaluated = "Interaction.RequestEvaluated"
Signals.SessionCompleted = "Interaction.SessionCompleted"
Signals.SessionCancelled = "Interaction.SessionCancelled"
Signals.ValidationFailed = "Interaction.ValidationFailed"
Signals.SnapshotCaptured = "Interaction.SnapshotCaptured"

return Signals

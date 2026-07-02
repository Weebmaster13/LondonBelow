--!strict
-- Server-only EventBus signals for Interaction Runtime Foundation.

local Signals = {}

Signals.InteractionRegistered = "Interaction.ObjectRegistered"
Signals.IntentRecorded = "Interaction.IntentRecorded"
Signals.LockRecorded = "Interaction.LockRecorded"
Signals.CooldownRecorded = "Interaction.CooldownRecorded"
Signals.ValidationFailed = "Interaction.ValidationFailed"
Signals.SnapshotCaptured = "Interaction.SnapshotCaptured"

return Signals

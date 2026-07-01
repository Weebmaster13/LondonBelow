--!strict
-- Server-only EventBus signal names for Monster AI foundation.

local Signals = {}

Signals.MonsterRegistered = "MonsterAI.MonsterRegistered"
Signals.IntentAccepted = "MonsterAI.IntentAccepted"
Signals.IntentRejected = "MonsterAI.IntentRejected"
Signals.IntentPlanned = "MonsterAI.IntentPlanned"
Signals.IntentDryRunApplied = "MonsterAI.IntentDryRunApplied"
Signals.ValidationFailed = "MonsterAI.ValidationFailed"
Signals.SnapshotCaptured = "MonsterAI.SnapshotCaptured"

return Signals

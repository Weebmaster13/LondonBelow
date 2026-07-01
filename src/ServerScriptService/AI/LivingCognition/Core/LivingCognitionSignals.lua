--!strict
-- Server-only EventBus signal names for Living Cognition.

local Signals = {}

Signals.EntityRegistered = "LivingCognition.EntityRegistered"
Signals.ObservationAccepted = "LivingCognition.ObservationAccepted"
Signals.ObservationRejected = "LivingCognition.ObservationRejected"
Signals.EvidenceCreated = "LivingCognition.EvidenceCreated"
Signals.HypothesisCreated = "LivingCognition.HypothesisCreated"
Signals.ThoughtPromoted = "LivingCognition.ThoughtPromoted"
Signals.BeliefUpdated = "LivingCognition.BeliefUpdated"
Signals.ValidationFailed = "LivingCognition.ValidationFailed"
Signals.SnapshotCaptured = "LivingCognition.SnapshotCaptured"

return Signals

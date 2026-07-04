--!strict

local Signals = {}

Signals.ReadinessChecklistRegistered = "AssetReadinessReview.ReadinessChecklistRegistered"
Signals.ReadinessFindingRegistered = "AssetReadinessReview.ReadinessFindingRegistered"
Signals.ReadinessGateRegistered = "AssetReadinessReview.ReadinessGateRegistered"
Signals.ReadinessDecisionRegistered = "AssetReadinessReview.ReadinessDecisionRegistered"
Signals.ReadinessAuditRegistered = "AssetReadinessReview.ReadinessAuditRegistered"
Signals.ValidationRejected = "AssetReadinessReview.ValidationRejected"
Signals.SnapshotCaptured = "AssetReadinessReview.SnapshotCaptured"

return Signals

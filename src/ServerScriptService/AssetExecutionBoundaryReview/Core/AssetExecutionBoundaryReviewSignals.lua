--!strict

local Signals = {}

Signals.BoundaryReviewRegistered = "AssetExecutionBoundaryReview.BoundaryReviewRegistered"
Signals.BoundaryRiskRegistered = "AssetExecutionBoundaryReview.BoundaryRiskRegistered"
Signals.BoundaryRequirementRegistered = "AssetExecutionBoundaryReview.BoundaryRequirementRegistered"
Signals.BoundaryAuditRegistered = "AssetExecutionBoundaryReview.BoundaryAuditRegistered"
Signals.ValidationRejected = "AssetExecutionBoundaryReview.ValidationRejected"
Signals.SnapshotCaptured = "AssetExecutionBoundaryReview.SnapshotCaptured"

return Signals

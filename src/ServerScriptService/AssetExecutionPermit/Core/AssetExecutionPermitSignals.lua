--!strict

local Signals = {}

Signals.ExecutionPermitRegistered = "AssetExecutionPermit.ExecutionPermitRegistered"
Signals.ExecutionPermitScopeRegistered = "AssetExecutionPermit.ExecutionPermitScopeRegistered"
Signals.ExecutionPermitRestrictionRegistered =
	"AssetExecutionPermit.ExecutionPermitRestrictionRegistered"
Signals.ExecutionPermitAuditRegistered = "AssetExecutionPermit.ExecutionPermitAuditRegistered"
Signals.ValidationRejected = "AssetExecutionPermit.ValidationRejected"
Signals.SnapshotCaptured = "AssetExecutionPermit.SnapshotCaptured"

return Signals

--!strict

local Signals = {}

Signals.RuntimeGateRegistered = "AssetRuntimeGate.RuntimeGateRegistered"
Signals.RuntimeGateCheckRegistered = "AssetRuntimeGate.RuntimeGateCheckRegistered"
Signals.RuntimeGateBlockRegistered = "AssetRuntimeGate.RuntimeGateBlockRegistered"
Signals.RuntimeGateAuditRegistered = "AssetRuntimeGate.RuntimeGateAuditRegistered"
Signals.ValidationRejected = "AssetRuntimeGate.ValidationRejected"
Signals.SnapshotCaptured = "AssetRuntimeGate.SnapshotCaptured"

return Signals

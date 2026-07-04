--!strict

local Signals = {}

Signals.ApprovalRecordRegistered = "AssetApprovalLedger.ApprovalRecordRegistered"
Signals.ApprovalConditionRegistered = "AssetApprovalLedger.ApprovalConditionRegistered"
Signals.ApprovalRevocationRegistered = "AssetApprovalLedger.ApprovalRevocationRegistered"
Signals.ApprovalAuditRegistered = "AssetApprovalLedger.ApprovalAuditRegistered"
Signals.ValidationRejected = "AssetApprovalLedger.ValidationRejected"
Signals.SnapshotCaptured = "AssetApprovalLedger.SnapshotCaptured"

return Signals

--!strict

local Signals = {}

Signals.GovernanceChainRegistered = "AssetGovernanceIntegration.GovernanceChainRegistered"
Signals.GovernanceRuntimeNodeRegistered =
	"AssetGovernanceIntegration.GovernanceRuntimeNodeRegistered"
Signals.GovernanceReferenceReviewRegistered =
	"AssetGovernanceIntegration.GovernanceReferenceReviewRegistered"
Signals.GovernanceIntegrationAuditRegistered =
	"AssetGovernanceIntegration.GovernanceIntegrationAuditRegistered"
Signals.ValidationRejected = "AssetGovernanceIntegration.ValidationRejected"
Signals.SnapshotCaptured = "AssetGovernanceIntegration.SnapshotCaptured"

return Signals

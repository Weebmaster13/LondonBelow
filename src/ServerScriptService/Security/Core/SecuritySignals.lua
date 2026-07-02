--!strict
-- EventBus signal names emitted by Security Boundary Runtime.

local Signals = {
	TrustPolicyRegistered = "Security.TrustPolicyRegistered",
	AuthorityRuleRegistered = "Security.AuthorityRuleRegistered",
	ExploitSignalRegistered = "Security.ExploitSignalRegistered",
	ClientRejectionRegistered = "Security.ClientRejectionRegistered",
	RemoteSafetyRegistered = "Security.RemoteSafetyRegistered",
	RateLimitRegistered = "Security.RateLimitRegistered",
	AuditRegistered = "Security.AuditRegistered",
	ValidationFailed = "Security.ValidationFailed",
	SnapshotCaptured = "Security.SnapshotCaptured",
}

return Signals

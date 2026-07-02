--!strict
-- Shared constants for Phase 34 Security / Anti-Exploit Boundary Foundation.

local Types = {}

Types.Mode = "ServerAuthoritativeSecurityPolicySchemaRuntime"

Types.SchemaType = {
	SecurityTrustPolicySchema = "SecurityTrustPolicySchema",
	SecurityAuthorityRuleSchema = "SecurityAuthorityRuleSchema",
	SecurityExploitSignalSchema = "SecurityExploitSignalSchema",
	SecurityClientRejectionSchema = "SecurityClientRejectionSchema",
	SecurityRemoteSafetySchema = "SecurityRemoteSafetySchema",
	SecurityRateLimitSchema = "SecurityRateLimitSchema",
	SecurityAuditSchema = "SecurityAuditSchema",
	SystemSecuritySchema = "SystemSecuritySchema",
}

Types.ResultCode = {
	Ok = "Ok",
	InvalidRequest = "InvalidRequest",
	DuplicateTrustPolicy = "DuplicateTrustPolicy",
	DuplicateAuthorityRule = "DuplicateAuthorityRule",
	DuplicateExploitSignal = "DuplicateExploitSignal",
	DuplicateClientRejection = "DuplicateClientRejection",
	DuplicateRemoteSafety = "DuplicateRemoteSafety",
	DuplicateRateLimit = "DuplicateRateLimit",
	DuplicateAudit = "DuplicateAudit",
	UnsafePayload = "UnsafePayload",
}

Types.Limits = {
	MaxTrustPolicies = 700,
	MaxAuthorityRules = 900,
	MaxExploitSignals = 700,
	MaxClientRejections = 700,
	MaxRemoteSafetyContracts = 900,
	MaxRateLimits = 900,
	MaxAudits = 500,
	MaxValidationFailures = 220,
	MaxSnapshotHistory = 80,
	MaxPayloadDepth = 9,
	MaxPayloadNodes = 360,
	MaxPayloadStringLength = 640,
	MaxTags = 32,
}

return Types

--!strict

local Types = {}

Types.Mode = "ServerAuthoritativeAssetApprovalLedgerSchemaRuntime"

Types.SchemaType = {
	ApprovalRecord = "ApprovalRecord",
	ApprovalCondition = "ApprovalCondition",
	ApprovalRevocation = "ApprovalRevocation",
	ApprovalAudit = "ApprovalAudit",
	SystemApprovalLedgerSchema = "SystemApprovalLedgerSchema",
}

Types.ApprovalKind = {
	DesignApproval = true,
	SafetyApproval = true,
	AccessibilityApproval = true,
	PerformanceApproval = true,
	ProductionApproval = true,
	ConditionalApproval = true,
	FutureApproval = true,
}

Types.ApprovalStatus = {
	Approved = true,
	ConditionallyApproved = true,
	Rejected = true,
	Revoked = true,
	Deferred = true,
	NeedsReview = true,
}

Types.ConditionKind = {
	MetadataCondition = true,
	SafetyCondition = true,
	AccessibilityCondition = true,
	PerformanceCondition = true,
	ProductionCondition = true,
	FutureCondition = true,
}

Types.RevocationKind = {
	SafetyRevocation = true,
	MetadataRevocation = true,
	PolicyRevocation = true,
	ProductionRevocation = true,
	TemporaryRevocation = true,
	FutureRevocation = true,
}

Types.AuditKind = {
	DesignAudit = true,
	SafetyAudit = true,
	AccessibilityAudit = true,
	PerformanceAudit = true,
	ProductionAudit = true,
	FutureAudit = true,
}

Types.AuditStatus = {
	Passed = true,
	Failed = true,
	Warning = true,
	Deferred = true,
	Blocked = true,
}

Types.Limits = {
	MaxApprovals = 900,
	MaxConditions = 1200,
	MaxRevocations = 700,
	MaxAudits = 500,
	MaxValidationFailures = 240,
	MaxSnapshotHistory = 60,
	MaxPayloadDepth = 8,
	MaxPayloadNodes = 450,
	MaxStringLength = 280,
	MaxTags = 32,
	MaxAuditFindings = 40,
	MaxApprovalChildren = 220,
}

return Types

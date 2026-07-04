--!strict

local Types = {}

Types.Mode = "ServerAuthoritativeAssetExecutionPermitSchemaRuntime"

Types.SchemaType = {
	ExecutionPermit = "ExecutionPermit",
	ExecutionPermitScope = "ExecutionPermitScope",
	ExecutionPermitRestriction = "ExecutionPermitRestriction",
	ExecutionPermitAudit = "ExecutionPermitAudit",
	SystemExecutionPermitSchema = "SystemExecutionPermitSchema",
}

Types.PermitKind = {
	DesignPermit = true,
	SafetyPermit = true,
	AccessibilityPermit = true,
	PerformancePermit = true,
	ProductionPermit = true,
	ConditionalPermit = true,
	FuturePermit = true,
}

Types.PermitStatus = {
	Issued = true,
	ConditionallyIssued = true,
	Rejected = true,
	Revoked = true,
	Deferred = true,
	NeedsReview = true,
}

Types.ScopeKind = {
	RuntimeScope = true,
	ChapterAgnosticScope = true,
	PresentationScope = true,
	GameplayScope = true,
	AccessibilityScope = true,
	PerformanceScope = true,
	FutureScope = true,
}

Types.RestrictionKind = {
	MetadataRestriction = true,
	SafetyRestriction = true,
	AccessibilityRestriction = true,
	PerformanceRestriction = true,
	ProductionRestriction = true,
	FutureRestriction = true,
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

Types.Severity = {
	Info = true,
	Low = true,
	Medium = true,
	High = true,
	Critical = true,
}

Types.Limits = {
	MaxPermits = 900,
	MaxScopes = 1200,
	MaxRestrictions = 1200,
	MaxAudits = 500,
	MaxValidationFailures = 240,
	MaxSnapshotHistory = 60,
	MaxPayloadDepth = 8,
	MaxPayloadNodes = 450,
	MaxStringLength = 280,
	MaxTags = 32,
	MaxAuditFindings = 40,
	MaxPermitChildren = 220,
}

return Types

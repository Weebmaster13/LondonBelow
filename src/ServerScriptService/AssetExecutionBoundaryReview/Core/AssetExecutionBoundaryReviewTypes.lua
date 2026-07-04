--!strict

local Types = {}

Types.Mode = "ServerAuthoritativeAssetExecutionBoundaryReviewSchemaRuntime"

Types.SchemaType = {
	BoundaryReview = "BoundaryReview",
	BoundaryRisk = "BoundaryRisk",
	BoundaryRequirement = "BoundaryRequirement",
	BoundaryReviewAudit = "BoundaryReviewAudit",
	SystemBoundaryReviewSchema = "SystemBoundaryReviewSchema",
}

Types.ReviewKind = {
	DesignReview = true,
	SafetyReview = true,
	AccessibilityReview = true,
	PerformanceReview = true,
	ProductionReview = true,
	ConditionalReview = true,
	FutureReview = true,
}

Types.ReviewStatus = {
	Open = true,
	Passed = true,
	Blocked = true,
	Deferred = true,
	NeedsReview = true,
}

Types.RiskKind = {
	SchemaRisk = true,
	ReadinessRisk = true,
	ApprovalRisk = true,
	PermitRisk = true,
	SafetyRisk = true,
	AccessibilityRisk = true,
	PerformanceRisk = true,
	FutureRisk = true,
}

Types.RequirementKind = {
	MetadataRequirement = true,
	SafetyRequirement = true,
	AccessibilityRequirement = true,
	PerformanceRequirement = true,
	ProductionRequirement = true,
	FutureRequirement = true,
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
	MaxReviews = 900,
	MaxRisks = 1200,
	MaxRequirements = 1200,
	MaxAudits = 500,
	MaxValidationFailures = 240,
	MaxSnapshotHistory = 60,
	MaxPayloadDepth = 8,
	MaxPayloadNodes = 450,
	MaxStringLength = 280,
	MaxTags = 32,
	MaxAuditFindings = 40,
	MaxReviewChildren = 220,
}

return Types

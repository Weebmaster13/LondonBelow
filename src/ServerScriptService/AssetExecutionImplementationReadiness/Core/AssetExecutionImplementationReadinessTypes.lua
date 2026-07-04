--!strict

local Types = {}

Types.Mode = "ServerAuthoritativeAssetExecutionImplementationReadinessSchemaRuntime"
Types.RuntimeProviderName = "assetExecutionImplementationReadinessRuntime"

Types.SchemaType = {
	ImplementationReadiness = "ImplementationReadiness",
	ImplementationReadinessChecklist = "ImplementationReadinessChecklist",
	ImplementationReadinessGap = "ImplementationReadinessGap",
	ImplementationReadinessAudit = "ImplementationReadinessAudit",
	SystemImplementationReadinessSchema = "SystemImplementationReadinessSchema",
}

Types.ReadinessKind = {
	ImplementationPlan = true,
	SafetyReadiness = true,
	AccessibilityReadiness = true,
	PerformanceReadiness = true,
	ProductionReadiness = true,
	ConditionalReadiness = true,
	FutureReadiness = true,
}

Types.ReadinessStatus = {
	Open = true,
	Passed = true,
	Blocked = true,
	Deferred = true,
	NeedsReview = true,
}

Types.ChecklistKind = {
	OwnershipChecklist = true,
	ValidationChecklist = true,
	DiagnosticsChecklist = true,
	SnapshotChecklist = true,
	CleanupChecklist = true,
	SafetyChecklist = true,
	AccessibilityChecklist = true,
	PerformanceChecklist = true,
	FutureChecklist = true,
}

Types.GapKind = {
	DesignGap = true,
	ValidationGap = true,
	DiagnosticsGap = true,
	SnapshotGap = true,
	CleanupGap = true,
	SafetyGap = true,
	AccessibilityGap = true,
	PerformanceGap = true,
	FutureGap = true,
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
	MaxReadinessRecords = 900,
	MaxChecklists = 1200,
	MaxGaps = 1200,
	MaxAudits = 500,
	MaxValidationFailures = 240,
	MaxSnapshotHistory = 60,
	MaxPayloadDepth = 8,
	MaxPayloadNodes = 450,
	MaxStringLength = 280,
	MaxTags = 32,
	MaxAuditFindings = 40,
	MaxReadinessChildren = 220,
}

return Types

--!strict

local Types = {}

Types.Mode = "ServerAuthoritativeAssetReadinessReviewSchemaRuntime"

Types.SchemaType = {
	ReadinessChecklist = "ReadinessChecklist",
	ReadinessFinding = "ReadinessFinding",
	ReadinessGate = "ReadinessGate",
	ReadinessDecision = "ReadinessDecision",
	ReadinessAudit = "ReadinessAudit",
	SystemReadinessReviewSchema = "SystemReadinessReviewSchema",
}

Types.ChecklistKind = {
	ManifestReadiness = true,
	UsagePlanReadiness = true,
	ExecutionBoundaryReadiness = true,
	AccessibilityReadiness = true,
	PerformanceReadiness = true,
	SafetyReadiness = true,
	ProductionReadiness = true,
	FutureReadiness = true,
}

Types.ReadinessTier = {
	Draft = true,
	InternalReview = true,
	Validated = true,
	Certified = true,
	Blocked = true,
	Future = true,
}

Types.FindingKind = {
	MissingMetadata = true,
	UnsafeField = true,
	ReferenceIssue = true,
	BudgetIssue = true,
	AccessibilityIssue = true,
	PolicyIssue = true,
	DocumentationIssue = true,
	FutureFinding = true,
}

Types.GateKind = {
	SchemaValidated = true,
	ManifestReferenceChecked = true,
	UsagePlanReferenceChecked = true,
	NoLoadingSurface = true,
	NoExecutionSurface = true,
	NoStorageMutation = true,
	AccessibilityChecked = true,
	BudgetChecked = true,
	FutureGate = true,
}

Types.DecisionKind = {
	ApproveForFutureExecutionDesign = true,
	NeedsMoreMetadata = true,
	RejectUnsafeBoundary = true,
	DeferReview = true,
	FutureDecision = true,
}

Types.DecisionStatus = {
	Approved = true,
	Rejected = true,
	Deferred = true,
	Blocked = true,
	NeedsReview = true,
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
	MaxChecklists = 900,
	MaxFindings = 1200,
	MaxGates = 1200,
	MaxDecisions = 700,
	MaxAudits = 500,
	MaxValidationFailures = 240,
	MaxSnapshotHistory = 60,
	MaxPayloadDepth = 8,
	MaxPayloadNodes = 450,
	MaxStringLength = 280,
	MaxTags = 32,
	MaxAuditFindings = 40,
	MaxChecklistChildren = 220,
}

return Types

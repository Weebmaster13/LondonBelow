--!strict

local Types = {}

Types.Mode = "ServerAuthoritativeAssetRuntimeGateSchemaRuntime"

Types.SchemaType = {
	RuntimeGate = "RuntimeGate",
	RuntimeGateCheck = "RuntimeGateCheck",
	RuntimeGateBlock = "RuntimeGateBlock",
	RuntimeGateAudit = "RuntimeGateAudit",
	SystemRuntimeGateSchema = "SystemRuntimeGateSchema",
}

Types.GateKind = {
	DesignGate = true,
	SafetyGate = true,
	AccessibilityGate = true,
	PerformanceGate = true,
	ProductionGate = true,
	ConditionalGate = true,
	FutureGate = true,
}

Types.GateStatus = {
	Open = true,
	Passed = true,
	Blocked = true,
	Deferred = true,
	NeedsReview = true,
}

Types.CheckKind = {
	SchemaCheck = true,
	ReadinessCheck = true,
	ApprovalCheck = true,
	PermitCheck = true,
	SafetyCheck = true,
	AccessibilityCheck = true,
	PerformanceCheck = true,
	FutureCheck = true,
}

Types.BlockKind = {
	MetadataBlock = true,
	SafetyBlock = true,
	AccessibilityBlock = true,
	PerformanceBlock = true,
	ProductionBlock = true,
	FutureBlock = true,
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
	MaxGates = 900,
	MaxChecks = 1200,
	MaxBlocks = 1200,
	MaxAudits = 500,
	MaxValidationFailures = 240,
	MaxSnapshotHistory = 60,
	MaxPayloadDepth = 8,
	MaxPayloadNodes = 450,
	MaxStringLength = 280,
	MaxTags = 32,
	MaxAuditFindings = 40,
	MaxGateChildren = 220,
}

return Types

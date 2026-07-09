--!strict

local Types = {}

Types.Mode = "ServerAuthoritativeAssetExecutionImplementationContractSchemaRuntime"
Types.RuntimeProviderName = "assetExecutionImplementationContractRuntime"

Types.SchemaType = {
	ImplementationContract = "ImplementationContract",
	ImplementationContractResponsibility = "ImplementationContractResponsibility",
	ImplementationContractBoundary = "ImplementationContractBoundary",
	ImplementationContractAudit = "ImplementationContractAudit",
	SystemAssetExecutionImplementationContractSchema = "SystemAssetExecutionImplementationContractSchema",
}

Types.ContractKind = {
	RuntimeImplementation = true,
	SafetyImplementation = true,
	AccessibilityImplementation = true,
	PerformanceImplementation = true,
	ProductionImplementation = true,
	ConditionalImplementation = true,
	FutureImplementation = true,
}

Types.ContractStatus = {
	Open = true,
	Passed = true,
	Blocked = true,
	Deferred = true,
	NeedsReview = true,
}

Types.ResponsibilityKind = {
	OwnershipResponsibility = true,
	ValidationResponsibility = true,
	DiagnosticsResponsibility = true,
	SnapshotResponsibility = true,
	CleanupResponsibility = true,
	SafetyResponsibility = true,
	AccessibilityResponsibility = true,
	PerformanceResponsibility = true,
	FutureResponsibility = true,
}

Types.BoundaryKind = {
	NoLoadingBoundary = true,
	NoExecutionBoundary = true,
	ClientAuthorityBoundary = true,
	StorageBoundary = true,
	SafetyBoundary = true,
	AccessibilityBoundary = true,
	PerformanceBoundary = true,
	FutureBoundary = true,
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
	MaxContracts = 900,
	MaxResponsibilities = 1200,
	MaxBoundaries = 1200,
	MaxAudits = 500,
	MaxValidationFailures = 240,
	MaxSnapshotHistory = 60,
	MaxPayloadDepth = 8,
	MaxPayloadNodes = 450,
	MaxStringLength = 280,
	MaxTags = 32,
	MaxAuditFindings = 40,
	MaxContractChildren = 220,
}

return Types

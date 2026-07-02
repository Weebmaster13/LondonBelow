--!strict
-- Shared constants for Phase 20 Gameplay Execution Bridge Foundation.

local Types = {}

Types.Mode = "ServerAuthoritativeDryRunGateway"

Types.Status = {
	Pending = "Pending",
	Approved = "Approved",
	Rejected = "Rejected",
	Cancelled = "Cancelled",
	Expired = "Expired",
	Queued = "Queued",
	Scheduled = "Scheduled",
	DryRun = "DryRun",
}

Types.ResultCode = {
	Ok = "Ok",
	InvalidRequest = "InvalidRequest",
	DuplicateExecution = "DuplicateExecution",
	DuplicateApproval = "DuplicateApproval",
	MissingApproval = "MissingApproval",
	MissingDependency = "MissingDependency",
	Expired = "Expired",
	UnsupportedExecutionType = "UnsupportedExecutionType",
	UnsafePayload = "UnsafePayload",
	QueueFull = "QueueFull",
}

Types.SupportedExecutionTypes = {
	GameplayStatePlan = true,
	PhysicalRuntimePlan = true,
	PresentationRuntimePlan = true,
	SystemCoordinationPlan = true,
}

Types.Limits = {
	MaxRequests = 240,
	MaxQueue = 160,
	MaxAuditRecords = 320,
	MaxValidationFailures = 160,
	MaxSnapshotHistory = 80,
	MaxSchedules = 160,
	MaxApprovalsPerRequest = 12,
	MaxDependenciesPerRequest = 24,
	MaxPayloadDepth = 8,
	MaxPayloadNodes = 260,
	MaxPayloadStringLength = 512,
	MaxPriority = 100,
	DefaultExpirationSeconds = 30,
}

return Types

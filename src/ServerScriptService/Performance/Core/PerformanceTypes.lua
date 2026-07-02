--!strict
-- Shared constants for Phase 33 Performance Budget Runtime Foundation.

local Types = {}

Types.Mode = "ServerAuthoritativePerformanceBudgetSchemaRuntime"

Types.SchemaType = {
	PerformanceBudgetSchema = "PerformanceBudgetSchema",
	PerformanceCategorySchema = "PerformanceCategorySchema",
	PerformanceThresholdSchema = "PerformanceThresholdSchema",
	PerformanceReportSchema = "PerformanceReportSchema",
	SystemPerformanceSchema = "SystemPerformanceSchema",
}

Types.ResultCode = {
	Ok = "Ok",
	InvalidRequest = "InvalidRequest",
	DuplicateBudget = "DuplicateBudget",
	DuplicateCategory = "DuplicateCategory",
	DuplicateThreshold = "DuplicateThreshold",
	DuplicateReport = "DuplicateReport",
	UnsafePayload = "UnsafePayload",
}

Types.Limits = {
	MaxBudgets = 900,
	MaxCategories = 700,
	MaxThresholds = 900,
	MaxReports = 500,
	MaxValidationFailures = 220,
	MaxSnapshotHistory = 80,
	MaxPayloadDepth = 9,
	MaxPayloadNodes = 360,
	MaxPayloadStringLength = 640,
	MaxTags = 32,
}

return Types

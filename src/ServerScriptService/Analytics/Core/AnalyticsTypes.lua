--!strict
-- Shared constants for Phase 31 Analytics Boundary Foundation.

local Types = {}

Types.Mode = "ServerAuthoritativeAnalyticsBoundarySchemaRuntime"

Types.SchemaType = {
	AnalyticsEventSchema = "AnalyticsEventSchema",
	AnalyticsMetricSchema = "AnalyticsMetricSchema",
	AnalyticsAggregationSchema = "AnalyticsAggregationSchema",
	AnalyticsConsentSchema = "AnalyticsConsentSchema",
	AnalyticsRetentionSchema = "AnalyticsRetentionSchema",
	AnalyticsReportSchema = "AnalyticsReportSchema",
	SystemAnalyticsSchema = "SystemAnalyticsSchema",
}

Types.ResultCode = {
	Ok = "Ok",
	InvalidRequest = "InvalidRequest",
	DuplicateEvent = "DuplicateEvent",
	DuplicateMetric = "DuplicateMetric",
	DuplicateAggregation = "DuplicateAggregation",
	DuplicateConsent = "DuplicateConsent",
	DuplicateRetention = "DuplicateRetention",
	DuplicateReport = "DuplicateReport",
	UnsafePayload = "UnsafePayload",
}

Types.Limits = {
	MaxEvents = 700,
	MaxMetrics = 900,
	MaxAggregations = 700,
	MaxConsents = 700,
	MaxRetentions = 700,
	MaxReports = 1200,
	MaxValidationFailures = 220,
	MaxSnapshotHistory = 80,
	MaxPayloadDepth = 9,
	MaxPayloadNodes = 360,
	MaxPayloadStringLength = 640,
	MaxTags = 32,
}

return Types

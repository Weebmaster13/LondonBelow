--!strict
-- Event names emitted by Analytics Boundary Foundation.

local Signals = {
	EventRegistered = "analyticsBoundary.EventRegistered",
	MetricRegistered = "analyticsBoundary.MetricRegistered",
	AggregationRegistered = "analyticsBoundary.AggregationRegistered",
	ConsentRegistered = "analyticsBoundary.ConsentRegistered",
	RetentionRegistered = "analyticsBoundary.RetentionRegistered",
	ReportRegistered = "analyticsBoundary.ReportRegistered",
	ValidationFailed = "analyticsBoundary.ValidationFailed",
	SnapshotCaptured = "analyticsBoundary.SnapshotCaptured",
}

return Signals

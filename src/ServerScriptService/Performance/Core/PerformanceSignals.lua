--!strict
-- EventBus signal names emitted by Performance Budget Runtime.

local Signals = {
	BudgetRegistered = "Performance.BudgetRegistered",
	CategoryRegistered = "Performance.CategoryRegistered",
	ThresholdRegistered = "Performance.ThresholdRegistered",
	ReportRegistered = "Performance.ReportRegistered",
	ValidationFailed = "Performance.ValidationFailed",
	SnapshotCaptured = "Performance.SnapshotCaptured",
}

return Signals

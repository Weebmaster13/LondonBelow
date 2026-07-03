--!strict
-- EventBus signal names emitted by Runtime Graph Runtime.

local Signals = {
	NodeRegistered = "RuntimeGraph.NodeRegistered",
	DependencyRegistered = "RuntimeGraph.DependencyRegistered",
	CapabilityRegistered = "RuntimeGraph.CapabilityRegistered",
	RequirementRegistered = "RuntimeGraph.RequirementRegistered",
	CompatibilityRegistered = "RuntimeGraph.CompatibilityRegistered",
	OrderingRegistered = "RuntimeGraph.OrderingRegistered",
	StartupPlanRegistered = "RuntimeGraph.StartupPlanRegistered",
	ShutdownPlanRegistered = "RuntimeGraph.ShutdownPlanRegistered",
	GroupRegistered = "RuntimeGraph.GroupRegistered",
	ValidationRecordRegistered = "RuntimeGraph.ValidationRecordRegistered",
	ValidationFailed = "RuntimeGraph.ValidationFailed",
	SnapshotCaptured = "RuntimeGraph.SnapshotCaptured",
}

return Signals

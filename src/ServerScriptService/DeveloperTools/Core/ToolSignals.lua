--!strict
-- Event names emitted by Developer Tooling Runtime Foundation.

local Signals = {
	ToolRegistered = "DeveloperTools.ToolRegistered",
	InspectionRegistered = "DeveloperTools.InspectionRegistered",
	CommandRegistered = "DeveloperTools.CommandRegistered",
	ReportRegistered = "DeveloperTools.ReportRegistered",
	PermissionRegistered = "DeveloperTools.PermissionRegistered",
	AuditRecorded = "DeveloperTools.AuditRecorded",
	ValidationFailed = "DeveloperTools.ValidationFailed",
	SnapshotCaptured = "DeveloperTools.SnapshotCaptured",
}

return Signals

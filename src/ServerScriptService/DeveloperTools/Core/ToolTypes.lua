--!strict
-- Shared constants for Phase 30 Developer Tooling Runtime Foundation.

local Types = {}

Types.Mode = "ServerAuthoritativeDeveloperToolingSchemaRuntime"

Types.SchemaType = {
	ToolDefinitionSchema = "ToolDefinitionSchema",
	InspectionRequestSchema = "InspectionRequestSchema",
	DebugPanelSchema = "DebugPanelSchema",
	CommandSchema = "CommandSchema",
	ReportPackageSchema = "ReportPackageSchema",
	PermissionSchema = "PermissionSchema",
	AuditRecordSchema = "AuditRecordSchema",
	SystemToolingSchema = "SystemToolingSchema",
}

Types.ResultCode = {
	Ok = "Ok",
	InvalidRequest = "InvalidRequest",
	DuplicateTool = "DuplicateTool",
	DuplicateInspection = "DuplicateInspection",
	DuplicateCommand = "DuplicateCommand",
	DuplicateReport = "DuplicateReport",
	DuplicatePermission = "DuplicatePermission",
	DuplicateAudit = "DuplicateAudit",
	UnsafePayload = "UnsafePayload",
}

Types.Limits = {
	MaxTools = 700,
	MaxInspections = 900,
	MaxCommands = 700,
	MaxReports = 700,
	MaxPermissions = 700,
	MaxAudits = 1200,
	MaxValidationFailures = 220,
	MaxSnapshotHistory = 80,
	MaxPayloadDepth = 9,
	MaxPayloadNodes = 360,
	MaxPayloadStringLength = 640,
	MaxTags = 32,
}

return Types

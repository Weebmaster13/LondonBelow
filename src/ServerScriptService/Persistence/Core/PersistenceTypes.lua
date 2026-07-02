--!strict
-- Shared constants for Phase 29 Data Persistence Boundary Foundation.

local Types = {}

Types.Mode = "ServerAuthoritativePersistenceBoundaryRuntime"

Types.SchemaType = {
	PersistenceRequestSchema = "PersistenceRequestSchema",
	SavePackageSchema = "SavePackageSchema",
	LoadPackageSchema = "LoadPackageSchema",
	MigrationSchema = "MigrationSchema",
	WritePolicySchema = "WritePolicySchema",
	RetryPolicySchema = "RetryPolicySchema",
	FailureRecordSchema = "FailureRecordSchema",
	SystemPersistenceSchema = "SystemPersistenceSchema",
}

Types.ResultCode = {
	Ok = "Ok",
	InvalidRequest = "InvalidRequest",
	DuplicateRequest = "DuplicateRequest",
	DuplicatePackage = "DuplicatePackage",
	DuplicatePolicy = "DuplicatePolicy",
	UnsafePayload = "UnsafePayload",
}

Types.Limits = {
	MaxRequests = 1200,
	MaxPackages = 1200,
	MaxMigrations = 400,
	MaxPolicies = 500,
	MaxFailures = 1000,
	MaxValidationFailures = 220,
	MaxSnapshotHistory = 80,
	MaxPayloadDepth = 9,
	MaxPayloadNodes = 360,
	MaxPayloadStringLength = 640,
	MaxTags = 32,
}

return Types

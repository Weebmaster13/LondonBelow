--!strict
-- Shared constants for Phase 29 Data Persistence Boundary Foundation.

local Types = {}

Types.Mode = "ServerAuthoritativePersistenceBoundaryRuntime"
Types.ProviderName = "persistenceRuntime"
Types.RuntimeVersion = 1

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
	DuplicateMigration = "DuplicateMigration",
	DuplicatePolicy = "DuplicatePolicy",
	DuplicateFailure = "DuplicateFailure",
	UnsafePayload = "UnsafePayload",
	DuplicateProvider = "DuplicateProvider",
	MissingProvider = "MissingProvider",
	ProviderUnavailable = "ProviderUnavailable",
	UnsupportedOperation = "UnsupportedOperation",
	StorageFailure = "StorageFailure",
	RetryExhausted = "RetryExhausted",
}

Types.Operation = {
	Load = "Load",
	Save = "Save",
	Delete = "Delete",
	Exists = "Exists",
	List = "List",
}

Types.ProviderKind = {
	MemoryProvider = "MemoryProvider",
	NullProvider = "NullProvider",
	FutureDataStoreProvider = "FutureDataStoreProvider",
	FutureProfileServiceProvider = "FutureProfileServiceProvider",
}

Types.RetryMode = {
	Immediate = "Immediate",
	LimitedRetry = "LimitedRetry",
	PermanentFailure = "PermanentFailure",
}

Types.FailureKind = {
	ValidationFailure = "ValidationFailure",
	ProviderUnavailable = "ProviderUnavailable",
	SerializationFailure = "SerializationFailure",
	StorageFailure = "StorageFailure",
	MigrationFailure = "MigrationFailure",
	UnsupportedOperation = "UnsupportedOperation",
	Timeout = "Timeout",
}

Types.Limits = {
	MaxRequests = 1200,
	MaxPackages = 1200,
	MaxMigrations = 400,
	MaxPolicies = 500,
	MaxFailures = 1000,
	MaxValidationFailures = 220,
	MaxSnapshotHistory = 80,
	MaxProviders = 12,
	MaxRequestHistory = 120,
	MaxResponseHistory = 120,
	MaxRetryHistory = 80,
	MaxEvidence = 180,
	MaxStoredRecords = 80,
	MaxRetryAttempts = 3,
	MaxPayloadDepth = 9,
	MaxPayloadNodes = 360,
	MaxPayloadStringLength = 640,
	MaxTags = 32,
}

return Types

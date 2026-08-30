--!strict

local Types = {}

Types.SchemaVersion = "1.0.0"
Types.RuntimeVersion = "195.0.0"
Types.ThemeExecutionVersion = "195.0.0"
Types.AnimationExecutionVersion = "192.1.0"
Types.ResponsiveLocalizationVersion = "190.1.0"
Types.RenderingHardeningVersion = "187.1.0"
Types.RuntimeState = table.freeze({
	Unconfigured = "Unconfigured",
	Ready = "Ready",
	Rendering = "Rendering",
	Committed = "Committed",
	Failed = "Failed",
	Shutdown = "Shutdown",
})
Types.TransactionState = table.freeze({
	Created = "Created",
	Staging = "Staging",
	Prepared = "Prepared",
	Committing = "Committing",
	Committed = "Committed",
	RollingBack = "RollingBack",
	RolledBack = "RolledBack",
	Failed = "Failed",
})
Types.FailureType = table.freeze({
	RuntimeShutdown = "RuntimeShutdown",
	RuntimeBusy = "RuntimeBusy",
	MountTargetMissing = "MountTargetMissing",
	MountTargetInvalid = "MountTargetInvalid",
	InvalidContract = "InvalidContract",
	UnsupportedSchemaVersion = "UnsupportedSchemaVersion",
	UnsupportedClass = "UnsupportedClass",
	UnsupportedProperty = "UnsupportedProperty",
	InvalidPropertyValue = "InvalidPropertyValue",
	DuplicateNode = "DuplicateNode",
	MissingParent = "MissingParent",
	HierarchyCycle = "HierarchyCycle",
	BudgetExceeded = "BudgetExceeded",
	InstanceCreationFailed = "InstanceCreationFailed",
	PropertyAssignmentFailed = "PropertyAssignmentFailed",
	ParentAssignmentFailed = "ParentAssignmentFailed",
	CommitFailed = "CommitFailed",
	RollbackFailed = "RollbackFailed",
	StaleRevision = "StaleRevision",
	RevisionConflict = "RevisionConflict",
	ContractTooLarge = "ContractTooLarge",
	IntegrityViolation = "IntegrityViolation",
	OwnershipViolation = "OwnershipViolation",
	InvalidMetadata = "InvalidMetadata",
})
Types.Limits = table.freeze({
	maxNodes = 1024,
	maxDepth = 48,
	maxPropertiesPerNode = 64,
	maxContractBytes = 1048576,
	maxStringLength = 8192,
	maxTagsPerNode = 32,
	maxTagLength = 64,
	maxTransactions = 128,
	maxFailures = 256,
	maxAuditRecords = 1024,
})

return table.freeze(Types)

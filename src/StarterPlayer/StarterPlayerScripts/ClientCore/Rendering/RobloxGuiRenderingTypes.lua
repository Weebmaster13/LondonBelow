--!strict

local Types = {}

Types.SchemaVersion = "1.0.0"
Types.RuntimeVersion = "186.1.0"
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
})
Types.Limits = table.freeze({
	maxNodes = 2048,
	maxDepth = 64,
	maxPropertiesPerNode = 96,
	maxTransactions = 128,
	maxFailures = 256,
	maxAuditRecords = 1024,
})

return table.freeze(Types)

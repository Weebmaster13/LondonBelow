--!strict
-- Event names emitted by Persistence Boundary Foundation.

local Signals = {
	RequestRegistered = "Persistence.RequestRegistered",
	PackageRegistered = "Persistence.PackageRegistered",
	MigrationRegistered = "Persistence.MigrationRegistered",
	PolicyRegistered = "Persistence.PolicyRegistered",
	FailureRecorded = "Persistence.FailureRecorded",
	ProviderRegistered = "Persistence.ProviderRegistered",
	ProviderUnregistered = "Persistence.ProviderUnregistered",
	RequestExecuted = "Persistence.RequestExecuted",
	ResponseValidated = "Persistence.ResponseValidated",
	ValidationFailed = "Persistence.ValidationFailed",
	SnapshotCaptured = "Persistence.SnapshotCaptured",
}

return Signals

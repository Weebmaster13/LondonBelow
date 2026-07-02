--!strict
-- Event names emitted by Persistence Boundary Foundation.

local Signals = {
	RequestRegistered = "Persistence.RequestRegistered",
	PackageRegistered = "Persistence.PackageRegistered",
	MigrationRegistered = "Persistence.MigrationRegistered",
	PolicyRegistered = "Persistence.PolicyRegistered",
	FailureRecorded = "Persistence.FailureRecorded",
	ValidationFailed = "Persistence.ValidationFailed",
	SnapshotCaptured = "Persistence.SnapshotCaptured",
}

return Signals

--!strict

local Types = {}

Types.ProviderName = "saveSessionRuntime"
Types.Mode = "ServerAuthoritativeSaveSessionRuntime"

Types.State = {
	New = "New",
	Opening = "Opening",
	Active = "Active",
	Dirty = "Dirty",
	Saving = "Saving",
	Loading = "Loading",
	Recovering = "Recovering",
	Closing = "Closing",
	Closed = "Closed",
	Failed = "Failed",
	Cancelled = "Cancelled",
}

Types.TransactionState = {
	Active = "Active",
	Committed = "Committed",
	RolledBack = "RolledBack",
	Cancelled = "Cancelled",
}

Types.ResultCode = {
	Ok = "Ok",
	InvalidSession = "InvalidSession",
	DuplicateSession = "DuplicateSession",
	UnknownSession = "UnknownSession",
	InvalidTransition = "InvalidTransition",
	LockRejected = "LockRejected",
	TransactionRejected = "TransactionRejected",
	Cancelled = "Cancelled",
	RecoveryFailed = "RecoveryFailed",
}

Types.Limits = {
	MaxSessions = 120,
	MaxEvidence = 220,
	MaxFailures = 120,
	MaxSnapshots = 80,
	MaxTransactions = 120,
	MaxStringLength = 160,
}

return Types

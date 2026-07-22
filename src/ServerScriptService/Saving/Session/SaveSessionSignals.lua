--!strict

local Signals = {
	SessionOpened = "SaveSession.SessionOpened",
	SessionClosed = "SaveSession.SessionClosed",
	DirtyChanged = "SaveSession.DirtyChanged",
	LockAcquired = "SaveSession.LockAcquired",
	LockReleased = "SaveSession.LockReleased",
	TransactionBegan = "SaveSession.TransactionBegan",
	TransactionCommitted = "SaveSession.TransactionCommitted",
	TransactionRolledBack = "SaveSession.TransactionRolledBack",
	TransactionCancelled = "SaveSession.TransactionCancelled",
	RecoveryCompleted = "SaveSession.RecoveryCompleted",
	ShutdownCompleted = "SaveSession.ShutdownCompleted",
	ValidationFailed = "SaveSession.ValidationFailed",
}

return Signals

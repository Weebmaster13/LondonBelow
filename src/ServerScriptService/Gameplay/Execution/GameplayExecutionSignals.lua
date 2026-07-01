--!strict

local GameplayExecutionSignals = {
	Requested = "GameplayExecution.Requested",
	Validated = "GameplayExecution.Validated",
	Rejected = "GameplayExecution.Rejected",
	Deferred = "GameplayExecution.Deferred",
	Applied = "GameplayExecution.Applied",
	Failed = "GameplayExecution.Failed",
	Cancelled = "GameplayExecution.Cancelled",
	Expired = "GameplayExecution.Expired",
	AdapterRegistered = "GameplayExecution.AdapterRegistered",
}

return GameplayExecutionSignals

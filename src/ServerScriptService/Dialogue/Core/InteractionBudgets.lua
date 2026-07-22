--!strict

local Serialization = require(script.Parent.DialogueSerialization)
local Types = require(script.Parent.DialogueInteractionTypes)

local Budgets = {}

function Budgets.inspect()
	return Serialization.deepCopy({
		pendingInteractions = Types.Limits.MaxPendingInteractions,
		nestedConversations = Types.Limits.MaxNestedConversations,
		waitingExecutions = Types.Limits.MaxWaitingExecutions,
		runtimeQueue = Types.Limits.MaxRuntimeEvents,
		interruptionDepth = Types.Limits.MaxInterruptions,
		timeoutRecords = Types.Limits.MaxTimeoutRecords,
		evidence = Types.Limits.MaxEvidence,
	})
end

return Budgets

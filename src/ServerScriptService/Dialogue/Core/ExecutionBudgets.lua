--!strict

local Serialization = require(script.Parent.DialogueSerialization)
local Types = require(script.Parent.DialogueExecutionTypes)

local Budgets = {}

function Budgets.inspect()
	return Serialization.deepCopy({
		simultaneousConversations = Types.Limits.MaxExecutionContexts,
		runtimeVariables = Types.Limits.MaxRuntimeVariables,
		nodeTransitions = Types.Limits.MaxTraversalHistory,
		executionHistory = Types.Limits.MaxTraversalHistory,
		evidenceEntries = Types.Limits.MaxEvidence,
		schedulerQueue = Types.Limits.MaxSchedulerQueue,
	})
end

return Budgets

--!strict

local Serialization = require(script.Parent.WorkflowSerialization)
local Types = require(script.Parent.WorkflowTypes)

local Budgets = {}

local resourceBudgets = {
	maxActiveWorkflows = Types.Limits.MaxActiveInstances,
	maxConcurrentWaits = Types.Limits.MaxConcurrentWaits,
	maxVariables = Types.Limits.MaxVariables,
	maxWorkflowDepth = Types.Limits.MaxWorkflowDepth,
	maxTransitionHistory = Types.Limits.MaxHistory,
}

local performanceBudgets = {
	registrationMs = 2,
	schedulingMs = 2,
	transitionMs = 2,
	timeoutEvaluationMs = 1,
	diagnosticsOverheadPercent = 5,
}

function Budgets.inspect()
	return {
		resourceBudgets = Serialization.deepCopy(resourceBudgets),
		performanceBudgets = Serialization.deepCopy(performanceBudgets),
	}
end

return Budgets

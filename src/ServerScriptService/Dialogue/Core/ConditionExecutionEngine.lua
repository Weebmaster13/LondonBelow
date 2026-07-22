--!strict

local Evidence = require(script.Parent.ExecutionEvidence)
local Metrics = require(script.Parent.ExecutionMetrics)
local Profiler = require(script.Parent.ExecutionProfiler)
local Serialization = require(script.Parent.DialogueSerialization)

local Conditions = {}

function Conditions.evaluate(condition: any, variables: any, workflowReference: any?)
	Metrics.increment("conditionsEvaluated")
	Profiler.record(condition.conditionId, "conditionEvaluationLatency", 0)
	local result = true
	if condition.conditionKind == "VariableEquals" then
		result = variables[condition.inputs.variableId] == condition.inputs.expectedValue
	end
	Evidence.record("execution condition evaluated", {
		conditionId = condition.conditionId,
		conditionKind = condition.conditionKind,
		result = result,
		workflowReference = Serialization.deepCopy(workflowReference),
	})
	return { ok = true, code = "Ok", result = result }
end

return Conditions

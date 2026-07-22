--!strict

local Evidence = require(script.Parent.ExecutionEvidence)
local Metrics = require(script.Parent.ExecutionMetrics)
local Serialization = require(script.Parent.DialogueSerialization)
local Types = require(script.Parent.DialogueExecutionTypes)

local Store = {}
local variablesByExecution = {}

function Store.initialize(executionId: string, variables: any)
	if type(variables) ~= "table" then
		return {
			ok = false,
			code = Types.FailureType.ValidationFailure,
			message = "variables must be a table",
		}
	end
	local count = 0
	for key in pairs(variables) do
		if type(key) ~= "string" or key == "" then
			return {
				ok = false,
				code = Types.FailureType.InvalidVariableMutation,
				message = "invalid variable key",
			}
		end
		count += 1
	end
	if count > Types.Limits.MaxRuntimeVariables then
		return {
			ok = false,
			code = Types.FailureType.LimitExceeded,
			message = "runtime variable limit exceeded",
		}
	end
	variablesByExecution[executionId] = Serialization.deepCopy(variables)
	return { ok = true, code = "Ok" }
end

function Store.read(executionId: string, variableId: string)
	local variables = variablesByExecution[executionId]
	return if variables then Serialization.deepCopy(variables[variableId]) else nil
end

function Store.write(executionId: string, variableId: string, value: any, nodeId: string)
	local variables = variablesByExecution[executionId]
	if variables == nil then
		return {
			ok = false,
			code = Types.FailureType.UnknownExecution,
			message = "unknown execution",
		}
	end
	local oldValue = Serialization.deepCopy(variables[variableId])
	variables[variableId] = Serialization.deepCopy(value)
	Metrics.increment("variableMutations")
	Evidence.record("variable mutation", {
		executionId = executionId,
		variableId = variableId,
		oldValue = oldValue,
		newValue = Serialization.deepCopy(value),
		nodeId = nodeId,
	})
	return { ok = true, code = "Ok" }
end

function Store.clone(executionId: string)
	return Serialization.deepCopy(variablesByExecution[executionId] or {})
end

function Store.clear()
	table.clear(variablesByExecution)
end

return Store

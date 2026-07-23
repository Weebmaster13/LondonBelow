--!strict

local Evidence = require(script.Parent.PresentationExecutionEvidence)
local Serialization = require(script.Parent.PresentationSerialization)
local Types = require(script.Parent.PresentationTypes)

local Engine = {}
local executions = {}
local order = {}
local nextOrdinal = 0

function Engine.create(request: any)
	if #order >= Types.ExecutionLimits.MaxActiveExecutions then
		return {
			ok = false,
			code = Types.ExecutionFailureType.LimitExceeded,
			message = "execution limit exceeded",
		}
	end
	if type(request) ~= "table" then
		return {
			ok = false,
			code = Types.ExecutionFailureType.InvalidExecution,
			message = "execution request must be a table",
		}
	end
	for _, field in ipairs({ "executionSessionId", "presentationSessionId", "consumerId" }) do
		if type(request[field]) ~= "string" or request[field] == "" then
			return {
				ok = false,
				code = Types.ExecutionFailureType.InvalidExecution,
				message = "invalid field " .. field,
			}
		end
	end
	if executions[request.executionSessionId] ~= nil then
		return {
			ok = false,
			code = Types.ExecutionFailureType.DuplicateExecution,
			message = "duplicate execution",
		}
	end
	nextOrdinal += 1
	local execution = {
		executionSessionId = request.executionSessionId,
		presentationSessionId = request.presentationSessionId,
		consumerId = request.consumerId,
		executionState = Types.ExecutionState.Created,
		synchronizationState = "Pending",
		queueOrdinal = request.queueOrdinal or nextOrdinal,
		executionOrdinal = nextOrdinal,
		runtimePriority = request.runtimePriority or 0,
		runtimeMetadata = Serialization.deepCopy(request.runtimeMetadata or {}),
	}
	executions[execution.executionSessionId] = execution
	order[#order + 1] = execution.executionSessionId
	Evidence.record("execution created", { executionSessionId = execution.executionSessionId })
	return { ok = true, code = "Ok", execution = Serialization.deepCopy(execution) }
end

function Engine.get(executionId: string)
	local execution = executions[executionId]
	return if execution then Serialization.deepCopy(execution) else nil
end

function Engine.update(executionId: string, patch: any)
	local execution = executions[executionId]
	if execution == nil then
		return {
			ok = false,
			code = Types.ExecutionFailureType.UnknownExecution,
			message = "unknown execution",
		}
	end
	for key, value in pairs(patch) do
		execution[key] = Serialization.deepCopy(value)
	end
	return { ok = true, code = "Ok", execution = Serialization.deepCopy(execution) }
end

function Engine.inspect()
	local result = {}
	for index, executionId in ipairs(order) do
		result[index] = Serialization.deepCopy(executions[executionId])
	end
	return result
end

function Engine.clear()
	table.clear(executions)
	table.clear(order)
	nextOrdinal = 0
end

return Engine

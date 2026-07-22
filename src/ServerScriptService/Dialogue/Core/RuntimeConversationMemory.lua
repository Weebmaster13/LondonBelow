--!strict

local Evidence = require(script.Parent.ExecutionEvidence)
local Serialization = require(script.Parent.DialogueSerialization)
local Types = require(script.Parent.DialogueExecutionTypes)

local Memory = {}
local contexts = {}
local order = {}
local nextOrdinal = 0

function Memory.create(context: any)
	if #order >= Types.Limits.MaxExecutionContexts then
		return {
			ok = false,
			code = Types.FailureType.LimitExceeded,
			message = "execution context limit exceeded",
		}
	end
	if type(context.executionId) ~= "string" or context.executionId == "" then
		return {
			ok = false,
			code = Types.FailureType.ValidationFailure,
			message = "invalid executionId",
		}
	end
	if contexts[context.executionId] ~= nil then
		return {
			ok = false,
			code = Types.FailureType.DuplicateExecution,
			message = "duplicate execution",
		}
	end
	nextOrdinal += 1
	local stored = Serialization.deepCopy(context)
	stored.history = {}
	stored.createdOrdinal = nextOrdinal
	stored.updatedOrdinal = nextOrdinal
	contexts[context.executionId] = stored
	order[#order + 1] = context.executionId
	Evidence.record("execution context created", { executionId = context.executionId })
	return { ok = true, code = "Ok", context = Serialization.deepCopy(stored) }
end

function Memory.get(executionId: string): any?
	local context = contexts[executionId]
	if context == nil then
		return nil
	end
	return Serialization.deepCopy(context)
end

function Memory.update(executionId: string, patch: any)
	local context = contexts[executionId]
	if context == nil then
		return {
			ok = false,
			code = Types.FailureType.UnknownExecution,
			message = "unknown execution",
		}
	end
	nextOrdinal += 1
	for key, value in pairs(patch) do
		context[key] = Serialization.deepCopy(value)
	end
	context.updatedOrdinal = nextOrdinal
	return { ok = true, code = "Ok", context = Serialization.deepCopy(context) }
end

function Memory.addHistory(executionId: string, entry: any)
	local context = contexts[executionId]
	if context == nil then
		return {
			ok = false,
			code = Types.FailureType.UnknownExecution,
			message = "unknown execution",
		}
	end
	if #context.history >= Types.Limits.MaxTraversalHistory then
		table.remove(context.history, 1)
	end
	context.history[#context.history + 1] = Serialization.deepCopy(entry)
	return { ok = true, code = "Ok" }
end

function Memory.inspect()
	local items = {}
	for index, executionId in ipairs(order) do
		items[index] = Serialization.deepCopy(contexts[executionId])
	end
	return items
end

function Memory.countActive()
	local count = 0
	for _, context in pairs(contexts) do
		if context.executionState ~= Types.ExecutionState.Closed then
			count += 1
		end
	end
	return count
end

function Memory.clear()
	table.clear(contexts)
	table.clear(order)
	nextOrdinal = 0
end

return Memory

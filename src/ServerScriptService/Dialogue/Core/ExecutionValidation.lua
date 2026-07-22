--!strict

local Memory = require(script.Parent.RuntimeConversationMemory)
local Types = require(script.Parent.DialogueExecutionTypes)

local Validation = {}

local validStates = {}
for _, state in pairs(Types.ExecutionState) do
	validStates[state] = true
end

function Validation.validateContext(context: any)
	if type(context) ~= "table" then
		return {
			ok = false,
			code = Types.FailureType.ValidationFailure,
			message = "context must be a table",
		}
	end
	for _, field in ipairs({
		"executionId",
		"conversationId",
		"dialogueId",
		"currentNodeId",
		"executionState",
	}) do
		if type(context[field]) ~= "string" or context[field] == "" then
			return {
				ok = false,
				code = Types.FailureType.ValidationFailure,
				message = "invalid execution context field " .. field,
			}
		end
	end
	if not validStates[context.executionState] then
		return {
			ok = false,
			code = Types.FailureType.InvalidExecutionState,
			message = "invalid execution state",
		}
	end
	if
		type(context.variables) ~= "table"
		or type(context.participants) ~= "table"
		or type(context.runtimeMetadata) ~= "table"
	then
		return {
			ok = false,
			code = Types.FailureType.ValidationFailure,
			message = "context collections must be tables",
		}
	end
	return { ok = true, code = "Ok" }
end

function Validation.validateRuntime()
	for _, context in ipairs(Memory.inspect()) do
		local result = Validation.validateContext(context)
		if not result.ok then
			return false, result.message
		end
	end
	return true, nil
end

return Validation

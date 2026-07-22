--!strict

local Evidence = require(script.Parent.CommandEvidence)
local Serialization = require(script.Parent.CommandSerialization)
local Types = require(script.Parent.CommandTypes)

local Execution = {}
local history: { any } = {}
local sequence = 0

local function trim()
	while #history > Types.Limits.MaxExecutionHistory do
		table.remove(history, 1)
	end
end

function Execution.execute(command: any, plan: any)
	sequence += 1
	if plan.missingRoute then
		local failed = {
			ok = false,
			code = Types.FailureType.NoHandler,
			commandId = command.commandId,
			commandType = command.commandType,
			status = Types.Status.Failed,
			failureReason = "no authoritative handler registered",
		}
		table.insert(history, Serialization.deepCopy(failed))
		trim()
		Evidence.record("command failed", failed)
		return failed
	end
	Evidence.record(
		"command execution started",
		{ commandId = command.commandId, handlerId = plan.handlerId }
	)
	local ok, response = pcall(plan.execute, Serialization.deepCopy(command), {
		commandId = command.commandId,
		commandType = command.commandType,
		handlerId = plan.handlerId,
		executionSequence = sequence,
	})
	local success = ok and (response == nil or response.success ~= false)
	local result = {
		ok = success,
		code = if success then "Ok" else Types.FailureType.ExecutionFailure,
		commandId = command.commandId,
		commandType = command.commandType,
		status = if success then Types.Status.Succeeded else Types.Status.Failed,
		resultCode = if response ~= nil then response.resultCode else nil,
		failureReason = if success
			then nil
			else if ok
				then tostring(response.failureReason or "malformed handler result")
				else tostring(response),
		metadata = if response ~= nil then response.metadata else nil,
		executionSequence = sequence,
	}
	table.insert(history, Serialization.deepCopy(result))
	trim()
	Evidence.record(if success then "command succeeded" else "command failed", result)
	return Serialization.deepCopy(result)
end

function Execution.inspect()
	return {
		executionSequence = sequence,
		history = Serialization.copyArray(history),
	}
end

function Execution.clear()
	table.clear(history)
	sequence = 0
end

return Execution

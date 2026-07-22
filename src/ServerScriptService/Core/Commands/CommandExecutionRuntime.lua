--!strict

local Evidence = require(script.Parent.CommandEvidence)
local Lifecycle = require(script.Parent.CommandLifecycle)
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
		local failedCommand =
			Lifecycle.transition(command, Types.Status.Failed, "completionTimestamp")
		local failed = {
			ok = false,
			code = Types.FailureType.NoHandler,
			failureCategory = Types.FailureType.RoutingFailure,
			commandId = command.commandId,
			commandType = command.commandType,
			status = Types.Status.Failed,
			commandResult = {
				status = Types.ResultStatus.Failure,
				executionDuration = 0,
				resultCode = Types.FailureType.NoHandler,
				output = {},
				diagnostics = {},
				evidenceReference = "command failed",
			},
			failureReason = "no authoritative handler registered",
		}
		if failedCommand ~= nil then
			failed.commandEnvelope = failedCommand
		end
		table.insert(history, Serialization.deepCopy(failed))
		trim()
		Evidence.record("command failed", failed)
		return failed
	end
	local executing, transitionReason =
		Lifecycle.transition(command, Types.Status.Executing, "executionTimestamp")
	if executing == nil then
		local failed = {
			ok = false,
			code = Types.FailureType.InternalRuntimeFailure,
			failureCategory = Types.FailureType.InternalRuntimeFailure,
			commandId = command.commandId,
			commandType = command.commandType,
			status = Types.Status.Failed,
			failureReason = transitionReason,
			commandResult = {
				status = Types.ResultStatus.Failure,
				executionDuration = 0,
				resultCode = Types.FailureType.InternalRuntimeFailure,
				output = {},
				diagnostics = {},
				evidenceReference = "illegal lifecycle transition",
			},
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
	local startedAt = os.clock()
	local ok, response = pcall(plan.execute, Serialization.deepCopy(executing), {
		commandId = command.commandId,
		commandType = command.commandType,
		handlerId = plan.handlerId,
		executionSequence = sequence,
	})
	local duration = os.clock() - startedAt
	local success = ok and (response == nil or response.success ~= false)
	local resultStatus = if success then Types.ResultStatus.Success else Types.ResultStatus.Failure
	local completedState = if success then Types.Status.Completed else Types.Status.Failed
	local commandResult = {
		status = resultStatus,
		executionDuration = duration,
		resultCode = if response ~= nil and response.resultCode ~= nil
			then response.resultCode
			else if success then "Ok" else Types.FailureType.ExecutionFailure,
		output = if response ~= nil and response.output ~= nil then response.output else {},
		diagnostics = if response ~= nil and response.diagnostics ~= nil
			then response.diagnostics
			else {},
		evidenceReference = if success then "command succeeded" else "command failed",
	}
	local completed = Lifecycle.transition(
		executing,
		completedState,
		"completionTimestamp",
		"resultReference",
		commandResult.resultCode
	)
	local result = {
		ok = success,
		code = if success then "Ok" else Types.FailureType.ExecutionFailure,
		failureCategory = if success then nil else Types.FailureType.ExecutionFailure,
		commandId = command.commandId,
		commandType = command.commandType,
		status = completedState,
		commandResult = commandResult,
		resultCode = commandResult.resultCode,
		failureReason = if success
			then nil
			else if ok
				then tostring(response.failureReason or "malformed handler result")
				else tostring(response),
		metadata = if response ~= nil then response.metadata else nil,
		executionSequence = sequence,
		commandEnvelope = completed,
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

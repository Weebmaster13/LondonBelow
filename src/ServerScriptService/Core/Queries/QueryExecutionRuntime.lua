--!strict

local Evidence = require(script.Parent.QueryEvidence)
local Lifecycle = require(script.Parent.QueryLifecycle)
local Serialization = require(script.Parent.QuerySerialization)
local Types = require(script.Parent.QueryTypes)

local Execution = {}
local history: { any } = {}
local sequence = 0

local function trim()
	while #history > Types.Limits.MaxExecutionHistory do
		table.remove(history, 1)
	end
end

function Execution.execute(query: any, plan: any)
	sequence += 1
	if plan.missingRoute then
		local failed = {
			ok = false,
			code = Types.FailureType.NoHandler,
			queryId = query.queryId,
			queryType = query.queryType,
			status = Types.Status.Failed,
			result = {
				status = Types.ResultStatus.Failure,
				resultCode = Types.FailureType.NoHandler,
				payload = {},
				metadata = {},
				executionDuration = 0,
				version = query.schemaVersion,
				evidence = "query failed",
			},
		}
		table.insert(history, Serialization.deepCopy(failed))
		trim()
		Evidence.record("query failed", failed)
		return failed
	end
	local executing, transitionReason =
		Lifecycle.transition(query, Types.Status.Executing, "executionTimestamp")
	if executing == nil then
		return {
			ok = false,
			code = Types.FailureType.ExecutionFailure,
			queryId = query.queryId,
			failureReason = transitionReason,
		}
	end
	local startedAt = os.clock()
	local ok, response = pcall(plan.execute, Serialization.deepCopy(executing), {
		queryId = query.queryId,
		queryType = query.queryType,
		handlerId = plan.handlerId,
		executionSequence = sequence,
	})
	local duration = os.clock() - startedAt
	local success = ok and (response == nil or response.success ~= false)
	local payload = if response ~= nil and response.payload ~= nil then response.payload else {}
	local result = {
		status = if success then Types.ResultStatus.Success else Types.ResultStatus.Failure,
		resultCode = if response ~= nil and response.resultCode ~= nil
			then response.resultCode
			else if success then "Ok" else Types.FailureType.ExecutionFailure,
		payload = payload,
		metadata = if response ~= nil and response.metadata ~= nil then response.metadata else {},
		executionDuration = duration,
		version = query.schemaVersion,
		evidence = if success then "query completed" else "query failed",
	}
	local completed = Lifecycle.transition(
		executing,
		if success then Types.Status.Completed else Types.Status.Failed,
		"completedTimestamp"
	)
	local output = {
		ok = success,
		code = if success then "Ok" else Types.FailureType.ExecutionFailure,
		queryId = query.queryId,
		queryType = query.queryType,
		status = if success then Types.Status.Completed else Types.Status.Failed,
		result = result,
		queryEnvelope = completed,
		executionSequence = sequence,
		failureReason = if success
			then nil
			else if ok
				then tostring(response.failureReason or "malformed handler result")
				else tostring(response),
	}
	table.insert(history, Serialization.deepCopy(output))
	trim()
	Evidence.record(if success then "query completed" else "query failed", output)
	return Serialization.deepCopy(output)
end

function Execution.inspect()
	return { executionSequence = sequence, history = Serialization.copyArray(history) }
end

function Execution.clear()
	table.clear(history)
	sequence = 0
end

return Execution

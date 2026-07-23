--!strict

local Evidence = require(script.Parent.PresentationExecutionEvidence)
local Metrics = require(script.Parent.PresentationExecutionMetrics)
local Sessions = require(script.Parent.SessionExecutionEngine)
local Types = require(script.Parent.PresentationTypes)

local Engine = {}

local allowed = {
	[Types.ExecutionState.Created] = { [Types.ExecutionState.Queued] = true },
	[Types.ExecutionState.Queued] = {
		[Types.ExecutionState.Assigned] = true,
		[Types.ExecutionState.Cancelled] = true,
		[Types.ExecutionState.Expired] = true,
	},
	[Types.ExecutionState.Assigned] = {
		[Types.ExecutionState.Preparing] = true,
		[Types.ExecutionState.Suspended] = true,
		[Types.ExecutionState.Cancelled] = true,
	},
	[Types.ExecutionState.Preparing] = {
		[Types.ExecutionState.Executing] = true,
		[Types.ExecutionState.Failed] = true,
	},
	[Types.ExecutionState.Executing] = {
		[Types.ExecutionState.WaitingForAcknowledgement] = true,
		[Types.ExecutionState.Completed] = true,
		[Types.ExecutionState.Suspended] = true,
		[Types.ExecutionState.Cancelled] = true,
		[Types.ExecutionState.Expired] = true,
		[Types.ExecutionState.Failed] = true,
	},
	[Types.ExecutionState.WaitingForAcknowledgement] = {
		[Types.ExecutionState.Acknowledged] = true,
		[Types.ExecutionState.Suspended] = true,
		[Types.ExecutionState.Cancelled] = true,
		[Types.ExecutionState.Expired] = true,
		[Types.ExecutionState.Failed] = true,
	},
	[Types.ExecutionState.Suspended] = {
		[Types.ExecutionState.Executing] = true,
		[Types.ExecutionState.Cancelled] = true,
		[Types.ExecutionState.Expired] = true,
	},
	[Types.ExecutionState.Acknowledged] = { [Types.ExecutionState.Completed] = true },
	[Types.ExecutionState.Completed] = { [Types.ExecutionState.Closed] = true },
	[Types.ExecutionState.Cancelled] = { [Types.ExecutionState.Closed] = true },
	[Types.ExecutionState.Expired] = { [Types.ExecutionState.Closed] = true },
	[Types.ExecutionState.Failed] = { [Types.ExecutionState.Closed] = true },
}

function Engine.transition(executionId: string, state: string, metadata: any?)
	local execution = Sessions.get(executionId)
	if execution == nil then
		return {
			ok = false,
			code = Types.ExecutionFailureType.UnknownExecution,
			message = "unknown execution",
		}
	end
	if not Types.isExecutionState(state) then
		return {
			ok = false,
			code = Types.ExecutionFailureType.InvalidLifecycleTransition,
			message = "invalid execution state",
		}
	end
	if
		allowed[execution.executionState] == nil
		or allowed[execution.executionState][state] ~= true
	then
		return {
			ok = false,
			code = Types.ExecutionFailureType.InvalidLifecycleTransition,
			message = "illegal execution transition",
		}
	end
	local updated = Sessions.update(executionId, {
		executionState = state,
		lifecycleMetadata = metadata or {},
	})
	if updated.ok then
		Metrics.increment("schedulerDecisions")
		if state == Types.ExecutionState.Completed then
			Metrics.increment("executionsCompleted")
		elseif state == Types.ExecutionState.Suspended then
			Metrics.increment("executionsSuspended")
		end
		Evidence.record(
			"execution lifecycle transition",
			{ executionSessionId = executionId, state = state }
		)
	end
	return updated
end

return Engine

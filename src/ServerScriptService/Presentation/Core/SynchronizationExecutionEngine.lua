--!strict

local Acknowledgements = require(script.Parent.AcknowledgementExecutionEngine)
local Evidence = require(script.Parent.PresentationExecutionEvidence)
local Metrics = require(script.Parent.PresentationExecutionMetrics)
local Serialization = require(script.Parent.PresentationSerialization)
local Sessions = require(script.Parent.SessionExecutionEngine)
local Types = require(script.Parent.PresentationTypes)

local Engine = {}
local records = {}

local terminal = {
	[Types.ExecutionState.Acknowledged] = true,
	[Types.ExecutionState.Completed] = true,
	[Types.ExecutionState.Cancelled] = true,
	[Types.ExecutionState.Expired] = true,
	[Types.ExecutionState.Failed] = true,
	[Types.ExecutionState.Closed] = true,
}

function Engine.resolve(executionId: string)
	local execution = Sessions.get(executionId)
	if execution == nil then
		return {
			ok = false,
			code = Types.ExecutionFailureType.UnknownExecution,
			message = "unknown execution",
		}
	end
	local record = {
		executionSessionId = executionId,
		presentationSessionId = execution.presentationSessionId,
		executionState = execution.executionState,
		latestAcknowledgement = Acknowledgements.latestForExecution(executionId),
		satisfied = terminal[execution.executionState] == true,
	}
	records[#records + 1] = Serialization.deepCopy(record)
	if #records > Types.ExecutionLimits.MaxExecutionSynchronizationRecords then
		table.remove(records, 1)
	end
	if record.satisfied then
		Metrics.increment("synchronizationCompletions")
		Evidence.record("synchronization completed", record)
	end
	return { ok = true, code = "Ok", synchronization = record }
end

function Engine.inspect()
	return Serialization.deepCopy(records)
end

function Engine.clear()
	table.clear(records)
end

return Engine

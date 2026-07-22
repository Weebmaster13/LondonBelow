--!strict

local Evidence = require(script.Parent.ExecutionEvidence)
local Metrics = require(script.Parent.ExecutionMetrics)
local Serialization = require(script.Parent.DialogueSerialization)
local Types = require(script.Parent.DialogueExecutionTypes)

local Scheduler = {}
local activeQueue = {}
local suspended = {}

function Scheduler.enqueue(executionId: string)
	if #activeQueue >= Types.Limits.MaxSchedulerQueue then
		return {
			ok = false,
			code = Types.FailureType.LimitExceeded,
			message = "scheduler queue limit exceeded",
		}
	end
	activeQueue[#activeQueue + 1] = executionId
	Metrics.increment("schedulerOperations")
	Evidence.record("execution scheduled", { executionId = executionId })
	return { ok = true, code = "Ok" }
end

function Scheduler.suspend(executionId: string, reason: string)
	suspended[executionId] = reason
	Metrics.increment("schedulerOperations")
	Evidence.record("execution suspended", { executionId = executionId, reason = reason })
	return { ok = true, code = "Ok" }
end

function Scheduler.resume(executionId: string)
	if suspended[executionId] == nil then
		return {
			ok = false,
			code = Types.FailureType.UnknownExecution,
			message = "execution is not suspended",
		}
	end
	suspended[executionId] = nil
	Metrics.increment("schedulerOperations")
	Evidence.record("execution resumed", { executionId = executionId })
	return Scheduler.enqueue(executionId)
end

function Scheduler.inspect()
	return {
		activeQueue = Serialization.deepCopy(activeQueue),
		suspended = Serialization.deepCopy(suspended),
	}
end

function Scheduler.clear()
	table.clear(activeQueue)
	table.clear(suspended)
end

return Scheduler

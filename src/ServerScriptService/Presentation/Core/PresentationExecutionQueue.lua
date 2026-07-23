--!strict

local Lifecycle = require(script.Parent.LifecycleExecutionEngine)
local Metrics = require(script.Parent.PresentationExecutionMetrics)
local Serialization = require(script.Parent.PresentationSerialization)
local Sessions = require(script.Parent.SessionExecutionEngine)
local Types = require(script.Parent.PresentationTypes)

local Queue = {}
local waiting = {}
local assigned = {}
local executing = {}
local suspended = {}
local cancelled = {}
local expired = {}

local function removeFrom(list: { string }, executionId: string)
	for index, value in ipairs(list) do
		if value == executionId then
			table.remove(list, index)
			return true
		end
	end
	return false
end

local function sortWaiting()
	table.sort(waiting, function(left, right)
		local leftExecution = Sessions.get(left)
		local rightExecution = Sessions.get(right)
		if leftExecution.runtimePriority ~= rightExecution.runtimePriority then
			return leftExecution.runtimePriority > rightExecution.runtimePriority
		end
		if leftExecution.queueOrdinal ~= rightExecution.queueOrdinal then
			return leftExecution.queueOrdinal < rightExecution.queueOrdinal
		end
		if leftExecution.executionOrdinal ~= rightExecution.executionOrdinal then
			return leftExecution.executionOrdinal < rightExecution.executionOrdinal
		end
		return left < right
	end)
end

function Queue.enqueue(executionId: string)
	if #waiting >= Types.ExecutionLimits.MaxQueuedExecutions then
		return {
			ok = false,
			code = Types.ExecutionFailureType.QueueOverflow,
			message = "execution queue overflow",
		}
	end
	local transitioned = Lifecycle.transition(executionId, Types.ExecutionState.Queued)
	if not transitioned.ok then
		return transitioned
	end
	waiting[#waiting + 1] = executionId
	sortWaiting()
	Metrics.increment("queueOperations")
	return { ok = true, code = "Ok", execution = transitioned.execution }
end

function Queue.dequeue()
	local executionId = table.remove(waiting, 1)
	if executionId == nil then
		return { ok = true, code = "Ok", empty = true }
	end
	Metrics.increment("queueOperations")
	return {
		ok = true,
		code = "Ok",
		executionId = executionId,
		execution = Sessions.get(executionId),
	}
end

function Queue.assign(executionId: string)
	removeFrom(waiting, executionId)
	local transitioned = Lifecycle.transition(executionId, Types.ExecutionState.Assigned)
	if not transitioned.ok then
		return transitioned
	end
	assigned[#assigned + 1] = executionId
	Metrics.increment("queueOperations")
	return transitioned
end

function Queue.execute(executionId: string)
	removeFrom(assigned, executionId)
	local transitioned = Lifecycle.transition(executionId, Types.ExecutionState.Preparing)
	if not transitioned.ok then
		return transitioned
	end
	local executingResult = Lifecycle.transition(executionId, Types.ExecutionState.Executing)
	if not executingResult.ok then
		return executingResult
	end
	executing[#executing + 1] = executionId
	Metrics.increment("executionsStarted")
	Metrics.increment("queueOperations")
	return executingResult
end

function Queue.suspend(executionId: string)
	removeFrom(executing, executionId)
	local transitioned = Lifecycle.transition(executionId, Types.ExecutionState.Suspended)
	if not transitioned.ok then
		return transitioned
	end
	suspended[#suspended + 1] = executionId
	return transitioned
end

function Queue.resume(executionId: string)
	removeFrom(suspended, executionId)
	local transitioned = Lifecycle.transition(executionId, Types.ExecutionState.Executing)
	if transitioned.ok then
		executing[#executing + 1] = executionId
		Metrics.increment("executionsResumed")
	end
	return transitioned
end

function Queue.cancel(executionId: string)
	removeFrom(waiting, executionId)
	removeFrom(assigned, executionId)
	removeFrom(executing, executionId)
	removeFrom(suspended, executionId)
	local transitioned = Lifecycle.transition(executionId, Types.ExecutionState.Cancelled)
	if transitioned.ok then
		cancelled[#cancelled + 1] = executionId
	end
	return transitioned
end

function Queue.expire(executionId: string)
	removeFrom(waiting, executionId)
	removeFrom(assigned, executionId)
	removeFrom(executing, executionId)
	removeFrom(suspended, executionId)
	local transitioned = Lifecycle.transition(executionId, Types.ExecutionState.Expired)
	if transitioned.ok then
		expired[#expired + 1] = executionId
	end
	return transitioned
end

function Queue.inspect()
	return Serialization.deepCopy({
		waiting = waiting,
		assigned = assigned,
		executing = executing,
		suspended = suspended,
		cancelled = cancelled,
		expired = expired,
	})
end

function Queue.clear()
	table.clear(waiting)
	table.clear(assigned)
	table.clear(executing)
	table.clear(suspended)
	table.clear(cancelled)
	table.clear(expired)
end

return Queue

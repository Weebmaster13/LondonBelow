--!strict

local Evidence = require(script.Parent.PresentationExecutionEvidence)
local Metrics = require(script.Parent.PresentationExecutionMetrics)
local Queue = require(script.Parent.PresentationExecutionQueue)
local Serialization = require(script.Parent.PresentationSerialization)
local Types = require(script.Parent.PresentationTypes)

local Scheduler = {}
local state = Types.ExecutionSchedulerState.Idle
local decisions = {}

local function setState(nextState: string)
	state = nextState
	decisions[#decisions + 1] = { state = nextState, ordinal = #decisions + 1 }
	Metrics.increment("schedulerDecisions")
	Evidence.record("scheduler decision", { state = nextState })
end

function Scheduler.scheduleNext()
	setState(Types.ExecutionSchedulerState.Scheduling)
	local dequeued = Queue.dequeue()
	if dequeued.empty then
		setState(Types.ExecutionSchedulerState.Idle)
		return dequeued
	end
	local assigned = Queue.assign(dequeued.executionId)
	if not assigned.ok then
		setState(Types.ExecutionSchedulerState.Idle)
		return assigned
	end
	setState(Types.ExecutionSchedulerState.Executing)
	return {
		ok = true,
		code = "Ok",
		executionId = dequeued.executionId,
		execution = assigned.execution,
	}
end

function Scheduler.suspend()
	setState(Types.ExecutionSchedulerState.Suspended)
end

function Scheduler.recover()
	setState(Types.ExecutionSchedulerState.Recovering)
	setState(Types.ExecutionSchedulerState.Idle)
end

function Scheduler.shutdown()
	setState(Types.ExecutionSchedulerState.Shutdown)
end

function Scheduler.inspect()
	return Serialization.deepCopy({ state = state, decisions = decisions })
end

function Scheduler.clear()
	state = Types.ExecutionSchedulerState.Idle
	table.clear(decisions)
end

return Scheduler

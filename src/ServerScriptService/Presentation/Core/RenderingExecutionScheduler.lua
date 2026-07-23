--!strict

local Evidence = require(script.Parent.RenderingExecutionEvidence)
local Lifecycle = require(script.Parent.RenderingExecutionLifecycle)
local Metrics = require(script.Parent.RenderingExecutionMetrics)
local Queue = require(script.Parent.RenderingExecutionQueue)
local RendererExecutions = require(script.Parent.RendererExecutionRegistry)
local Sessions = require(script.Parent.RenderingExecutionSessionRegistry)
local Types = require(script.Parent.PresentationTypes)

local Scheduler = {}
local state = Types.RenderingExecutionSchedulerState.Idle
local nextExecutionOrdinal = 0

function Scheduler.scheduleNext()
	if state == Types.RenderingExecutionSchedulerState.Shutdown then
		return {
			ok = false,
			code = Types.RenderingExecutionFailureType.SchedulerShutdown,
			message = "scheduler is shut down",
		}
	end
	state = Types.RenderingExecutionSchedulerState.Scheduling
	local dequeued = Queue.dequeue()
	if not dequeued.ok or dequeued.code == "Empty" then
		state = Types.RenderingExecutionSchedulerState.Idle
		return dequeued
	end
	local sessionId = dequeued.renderingExecutionSessionId
	local scheduled = Lifecycle.transition(sessionId, Types.RenderingExecutionState.Scheduled)
	if not scheduled.ok then
		state = Types.RenderingExecutionSchedulerState.Idle
		return scheduled
	end
	nextExecutionOrdinal += 1
	local session = Sessions.get(sessionId)
	Sessions.update(sessionId, {
		schedulerState = Types.RenderingExecutionSchedulerState.Executing,
		executionOrdinal = nextExecutionOrdinal,
	})
	RendererExecutions.assign(session.rendererId, sessionId)
	state = Types.RenderingExecutionSchedulerState.Executing
	Evidence.record(
		"execution scheduled",
		{ renderingExecutionSessionId = sessionId, executionOrdinal = nextExecutionOrdinal }
	)
	return { ok = true, code = "Ok", renderingExecutionSessionId = sessionId }
end

function Scheduler.execute(sessionId: string)
	local session = Sessions.get(sessionId)
	if session == nil then
		return {
			ok = false,
			code = Types.RenderingExecutionFailureType.UnknownExecutionSession,
			message = "unknown execution session",
		}
	end
	local transition = Lifecycle.transition(sessionId, Types.RenderingExecutionState.Executing)
	if not transition.ok then
		return transition
	end
	RendererExecutions.activate(session.rendererId, sessionId)
	Metrics.increment("activeExecutions")
	Evidence.record("execution executing", { renderingExecutionSessionId = sessionId })
	return { ok = true, code = "Ok" }
end

function Scheduler.recover()
	state = Types.RenderingExecutionSchedulerState.Recovering
	Evidence.record("execution recovery", {
		schedulerState = state,
		queue = Queue.inspect(),
		workloads = RendererExecutions.inspect(),
	})
	state = Types.RenderingExecutionSchedulerState.Idle
	return { ok = true, code = "Ok" }
end

function Scheduler.shutdown()
	state = Types.RenderingExecutionSchedulerState.Shutdown
	Evidence.record("scheduler shutdown", {})
end

function Scheduler.inspect()
	return {
		state = state,
		nextExecutionOrdinal = nextExecutionOrdinal,
		queue = Queue.inspect(),
		workloads = RendererExecutions.inspect(),
	}
end

function Scheduler.clear()
	state = Types.RenderingExecutionSchedulerState.Idle
	nextExecutionOrdinal = 0
end

return Scheduler

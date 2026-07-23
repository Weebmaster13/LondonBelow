--!strict

local Evidence = require(script.Parent.RenderingExecutionEvidence)
local Metrics = require(script.Parent.RenderingExecutionMetrics)
local Sessions = require(script.Parent.RenderingExecutionSessionRegistry)
local Types = require(script.Parent.PresentationTypes)

local Lifecycle = {}

local allowed = {
	Created = { Queued = true, Cancelled = true, Expired = true, Failed = true },
	Queued = { Scheduled = true, Suspended = true, Cancelled = true, Expired = true },
	Scheduled = { Executing = true, Suspended = true, Cancelled = true, Expired = true },
	Executing = {
		WaitingAcknowledgement = true,
		Suspended = true,
		Cancelled = true,
		Expired = true,
		Failed = true,
	},
	WaitingAcknowledgement = {
		Acknowledged = true,
		Cancelled = true,
		Expired = true,
		Failed = true,
	},
	Acknowledged = { Completed = true, Failed = true },
	Completed = { Closed = true },
	Suspended = { Queued = true, Cancelled = true, Expired = true },
	Cancelled = {},
	Failed = {},
	Expired = {},
	Closed = {},
}

function Lifecycle.transition(sessionId: string, nextState: string)
	if not Types.isRenderingExecutionState(nextState) then
		return {
			ok = false,
			code = Types.RenderingExecutionFailureType.InvalidExecutionState,
			message = "invalid execution state",
		}
	end
	local session = Sessions.get(sessionId)
	if session == nil then
		return {
			ok = false,
			code = Types.RenderingExecutionFailureType.UnknownExecutionSession,
			message = "unknown execution session",
		}
	end
	local transitions = allowed[session.executionState] or {}
	if transitions[nextState] ~= true then
		return {
			ok = false,
			code = Types.RenderingExecutionFailureType.InvalidLifecycleTransition,
			message = "illegal execution transition",
		}
	end
	local result = Sessions.update(sessionId, { executionState = nextState })
	Evidence.record(
		"execution lifecycle transition",
		{ renderingExecutionSessionId = sessionId, from = session.executionState, to = nextState }
	)
	if nextState == Types.RenderingExecutionState.Completed then
		Metrics.increment("completedExecutions")
	elseif nextState == Types.RenderingExecutionState.Cancelled then
		Metrics.increment("cancelledExecutions")
	elseif nextState == Types.RenderingExecutionState.Expired then
		Metrics.increment("expiredExecutions")
	end
	return result
end

return Lifecycle

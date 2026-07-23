--!strict

local Evidence = require(script.Parent.RenderingRuntimeEvidence)
local Metrics = require(script.Parent.RenderingRuntimeMetrics)
local Sessions = require(script.Parent.RenderingSessionRegistry)
local Types = require(script.Parent.PresentationTypes)

local Lifecycle = {}

local allowed = {
	Created = { Validated = true, Rejected = true },
	Validated = { PendingRenderer = true },
	PendingRenderer = { Assigned = true, Expired = true, Failed = true },
	Assigned = { Preparing = true, Cancelled = true, Failed = true },
	Preparing = { Ready = true, Failed = true },
	Ready = { Acknowledged = true, Cancelled = true, Failed = true },
	Acknowledged = { Completed = true, Failed = true },
	Completed = { Closed = true },
	Failed = {},
	Cancelled = {},
	Expired = {},
	Rejected = {},
	Closed = {},
}

function Lifecycle.transition(sessionId: string, nextState: string)
	if not Types.isRenderingRuntimeLifecycleState(nextState) then
		return {
			ok = false,
			code = Types.RenderingRuntimeFailureType.InvalidLifecycleTransition,
			message = "invalid lifecycle state",
		}
	end
	local session = Sessions.get(sessionId)
	if session == nil then
		return {
			ok = false,
			code = Types.RenderingRuntimeFailureType.UnknownSession,
			message = "unknown rendering session",
		}
	end
	local transitions = allowed[session.lifecycleState] or {}
	if transitions[nextState] ~= true then
		return {
			ok = false,
			code = Types.RenderingRuntimeFailureType.InvalidLifecycleTransition,
			message = "illegal lifecycle transition",
		}
	end
	local result = Sessions.update(sessionId, { lifecycleState = nextState })
	Metrics.increment("lifecycleTransitions")
	Evidence.record("lifecycle transition", {
		renderingSessionId = sessionId,
		from = session.lifecycleState,
		to = nextState,
	})
	return result
end

return Lifecycle

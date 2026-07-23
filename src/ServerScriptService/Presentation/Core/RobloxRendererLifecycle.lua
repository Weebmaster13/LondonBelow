--!strict

local Evidence = require(script.Parent.RobloxRenderingSessionEvidence)
local Metrics = require(script.Parent.RobloxRenderingSessionMetrics)
local Sessions = require(script.Parent.RobloxRenderingSessionRegistry)
local Types = require(script.Parent.PresentationTypes)

local Lifecycle = {}

local allowed = {
	[Types.RobloxRenderingSessionState.Created] = {
		[Types.RobloxRenderingSessionState.Mapped] = true,
		[Types.RobloxRenderingSessionState.Cancelled] = true,
	},
	[Types.RobloxRenderingSessionState.Mapped] = {
		[Types.RobloxRenderingSessionState.Reserved] = true,
		[Types.RobloxRenderingSessionState.Cancelled] = true,
	},
	[Types.RobloxRenderingSessionState.Reserved] = {
		[Types.RobloxRenderingSessionState.Scheduled] = true,
		[Types.RobloxRenderingSessionState.Released] = true,
		[Types.RobloxRenderingSessionState.Expired] = true,
	},
	[Types.RobloxRenderingSessionState.Scheduled] = {
		[Types.RobloxRenderingSessionState.WaitingExecution] = true,
		[Types.RobloxRenderingSessionState.Released] = true,
		[Types.RobloxRenderingSessionState.Cancelled] = true,
	},
	[Types.RobloxRenderingSessionState.WaitingExecution] = {
		[Types.RobloxRenderingSessionState.Released] = true,
		[Types.RobloxRenderingSessionState.Failed] = true,
	},
	[Types.RobloxRenderingSessionState.Released] = {
		[Types.RobloxRenderingSessionState.Closed] = true,
	},
}

function Lifecycle.transition(sessionId: string, nextState: string)
	if not Types.isRobloxRenderingSessionState(nextState) then
		return {
			ok = false,
			code = Types.RobloxRenderingSessionFailureType.InvalidLifecycleTransition,
			message = "invalid lifecycle state",
		}
	end
	local session = Sessions.get(sessionId)
	if session == nil then
		return {
			ok = false,
			code = Types.RobloxRenderingSessionFailureType.UnknownSession,
			message = "unknown session",
		}
	end
	if not (allowed[session.lifecycleState] and allowed[session.lifecycleState][nextState]) then
		return {
			ok = false,
			code = Types.RobloxRenderingSessionFailureType.InvalidLifecycleTransition,
			message = "illegal lifecycle transition",
		}
	end
	Sessions.update(sessionId, {
		lifecycleState = nextState,
		sessionState = nextState,
	})
	Metrics.increment("lifecycleTransitions")
	Evidence.record(
		"lifecycle transition",
		{ robloxRenderingSessionId = sessionId, nextState = nextState }
	)
	return { ok = true, code = "Ok" }
end

return Lifecycle

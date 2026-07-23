--!strict

local Evidence = require(script.Parent.PresentationEvidence)
local Metrics = require(script.Parent.PresentationMetrics)
local Sessions = require(script.Parent.PresentationSessionRegistry)
local Types = require(script.Parent.PresentationTypes)

local Manager = {}

local allowed = {
	[Types.RuntimeSessionState.Created] = { [Types.RuntimeSessionState.Queued] = true },
	[Types.RuntimeSessionState.Queued] = {
		[Types.RuntimeSessionState.Assigned] = true,
		[Types.RuntimeSessionState.Cancelled] = true,
	},
	[Types.RuntimeSessionState.Assigned] = {
		[Types.RuntimeSessionState.Preparing] = true,
		[Types.RuntimeSessionState.Suspended] = true,
		[Types.RuntimeSessionState.Cancelled] = true,
	},
	[Types.RuntimeSessionState.Suspended] = {
		[Types.RuntimeSessionState.Assigned] = true,
		[Types.RuntimeSessionState.Cancelled] = true,
	},
	[Types.RuntimeSessionState.Preparing] = {
		[Types.RuntimeSessionState.Ready] = true,
		[Types.RuntimeSessionState.Failed] = true,
	},
	[Types.RuntimeSessionState.Ready] = {
		[Types.RuntimeSessionState.Acknowledged] = true,
		[Types.RuntimeSessionState.Failed] = true,
	},
	[Types.RuntimeSessionState.Acknowledged] = {
		[Types.RuntimeSessionState.Completed] = true,
		[Types.RuntimeSessionState.Failed] = true,
	},
	[Types.RuntimeSessionState.Completed] = { [Types.RuntimeSessionState.Closed] = true },
	[Types.RuntimeSessionState.Cancelled] = { [Types.RuntimeSessionState.Closed] = true },
	[Types.RuntimeSessionState.Expired] = { [Types.RuntimeSessionState.Closed] = true },
	[Types.RuntimeSessionState.Failed] = { [Types.RuntimeSessionState.Closed] = true },
}

function Manager.transition(sessionId: string, nextState: string, metadata: any?)
	local session = Sessions.get(sessionId)
	if session == nil then
		return {
			ok = false,
			code = Types.RuntimeFailureType.UnknownSession,
			message = "unknown session",
		}
	end
	if not Types.isRuntimeSessionState(nextState) then
		return {
			ok = false,
			code = Types.RuntimeFailureType.InvalidLifecycleTransition,
			message = "invalid lifecycle state",
		}
	end
	if
		allowed[session.lifecycleState] == nil
		or allowed[session.lifecycleState][nextState] ~= true
	then
		return {
			ok = false,
			code = Types.RuntimeFailureType.InvalidLifecycleTransition,
			message = "illegal lifecycle transition",
		}
	end
	local updated = Sessions.update(sessionId, {
		lifecycleState = nextState,
		lifecycleMetadata = metadata or {},
	})
	if updated.ok then
		Metrics.increment("lifecycleTransitions")
		if nextState == Types.RuntimeSessionState.Completed then
			Metrics.increment("sessionsCompleted")
		end
		Evidence.record(
			"PresentationLifecycleTransition",
			{ presentationSessionId = sessionId, state = nextState },
			Types.Limits.MaxEvidence
		)
	end
	return updated
end

return Manager

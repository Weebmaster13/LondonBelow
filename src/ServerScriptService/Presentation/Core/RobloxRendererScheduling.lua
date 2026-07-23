--!strict

local Evidence = require(script.Parent.RobloxRenderingSessionEvidence)
local Metrics = require(script.Parent.RobloxRenderingSessionMetrics)
local Serialization = require(script.Parent.PresentationSerialization)
local Sessions = require(script.Parent.RobloxRenderingSessionRegistry)
local Types = require(script.Parent.PresentationTypes)

local Scheduling = {}
local queue = {}
local nextQueueOrdinal = 0
local nextSchedulerOrdinal = 0

function Scheduling.queue(sessionId: string)
	local session = Sessions.get(sessionId)
	if session == nil then
		return {
			ok = false,
			code = Types.RobloxRenderingSessionFailureType.UnknownSession,
			message = "unknown session",
		}
	end
	if session.lifecycleState ~= Types.RobloxRenderingSessionState.Reserved then
		return {
			ok = false,
			code = Types.RobloxRenderingSessionFailureType.InvalidSchedulingState,
			message = "session must be reserved",
		}
	end
	nextQueueOrdinal += 1
	queue[#queue + 1] = sessionId
	Sessions.update(sessionId, {
		queueOrdinal = nextQueueOrdinal,
		schedulingState = Types.RobloxRendererSchedulingState.Queued,
		dispatchEligibility = true,
	})
	Metrics.increment("schedulingOperations")
	Evidence.record("scheduler update", {
		robloxRenderingSessionId = sessionId,
		schedulingState = Types.RobloxRendererSchedulingState.Queued,
	})
	return { ok = true, code = "Ok" }
end

function Scheduling.scheduleNext()
	if #queue == 0 then
		return { ok = true, code = "Empty" }
	end
	table.sort(queue, function(leftId, rightId)
		local left = Sessions.get(leftId)
		local right = Sessions.get(rightId)
		if left.runtimePriority ~= right.runtimePriority then
			return left.runtimePriority > right.runtimePriority
		end
		if left.queueOrdinal ~= right.queueOrdinal then
			return left.queueOrdinal < right.queueOrdinal
		end
		return left.robloxRenderingSessionId < right.robloxRenderingSessionId
	end)
	local sessionId = table.remove(queue, 1)
	nextSchedulerOrdinal += 1
	Sessions.update(sessionId, {
		schedulerOrdinal = nextSchedulerOrdinal,
		schedulingState = Types.RobloxRendererSchedulingState.Scheduled,
		sessionState = Types.RobloxRenderingSessionState.Scheduled,
		lifecycleState = Types.RobloxRenderingSessionState.Scheduled,
		dispatchEligibility = true,
	})
	Metrics.increment("schedulingOperations")
	Evidence.record("scheduler update", {
		robloxRenderingSessionId = sessionId,
		schedulingState = Types.RobloxRendererSchedulingState.Scheduled,
	})
	return { ok = true, code = "Ok", robloxRenderingSessionId = sessionId }
end

function Scheduling.waitForExecution(sessionId: string)
	local session = Sessions.get(sessionId)
	if session == nil then
		return {
			ok = false,
			code = Types.RobloxRenderingSessionFailureType.UnknownSession,
			message = "unknown session",
		}
	end
	if session.schedulingState ~= Types.RobloxRendererSchedulingState.Scheduled then
		return {
			ok = false,
			code = Types.RobloxRenderingSessionFailureType.InvalidSchedulingState,
			message = "session must be scheduled",
		}
	end
	Sessions.update(sessionId, {
		schedulingState = Types.RobloxRendererSchedulingState.WaitingExecution,
		sessionState = Types.RobloxRenderingSessionState.WaitingExecution,
		lifecycleState = Types.RobloxRenderingSessionState.WaitingExecution,
	})
	Evidence.record("scheduler update", {
		robloxRenderingSessionId = sessionId,
		schedulingState = Types.RobloxRendererSchedulingState.WaitingExecution,
	})
	return { ok = true, code = "Ok" }
end

function Scheduling.inspect()
	return Serialization.deepCopy({
		queue = queue,
		nextQueueOrdinal = nextQueueOrdinal,
		nextSchedulerOrdinal = nextSchedulerOrdinal,
	})
end

function Scheduling.clear()
	table.clear(queue)
	nextQueueOrdinal = 0
	nextSchedulerOrdinal = 0
end

return Scheduling

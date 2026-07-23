--!strict

local Evidence = require(script.Parent.PresentationEvidence)
local Lifecycle = require(script.Parent.PresentationLifecycleManager)
local Metrics = require(script.Parent.PresentationMetrics)
local Serialization = require(script.Parent.PresentationSerialization)
local Sessions = require(script.Parent.PresentationSessionRegistry)
local Types = require(script.Parent.PresentationTypes)

local Queue = {}
local queued = {}
local assigned = {}
local suspended = {}
local cancelled = {}

local function sortQueued()
	table.sort(queued, function(left, right)
		local leftSession = Sessions.get(left)
		local rightSession = Sessions.get(right)
		if leftSession.priority ~= rightSession.priority then
			return leftSession.priority > rightSession.priority
		end
		if leftSession.queueOrdinal ~= rightSession.queueOrdinal then
			return leftSession.queueOrdinal < rightSession.queueOrdinal
		end
		return left < right
	end)
end

local function removeFrom(list: { string }, sessionId: string)
	for index, value in ipairs(list) do
		if value == sessionId then
			table.remove(list, index)
			return true
		end
	end
	return false
end

function Queue.enqueue(sessionId: string)
	if #queued >= Types.Limits.MaxRuntimeQueuedSessions then
		return {
			ok = false,
			code = Types.RuntimeFailureType.QueueOverflow,
			message = "queue overflow",
		}
	end
	local transitioned = Lifecycle.transition(sessionId, Types.RuntimeSessionState.Queued)
	if not transitioned.ok then
		return transitioned
	end
	queued[#queued + 1] = sessionId
	sortQueued()
	Metrics.increment("sessionsQueued")
	Metrics.increment("queueOperations")
	Evidence.record(
		"PresentationSessionQueued",
		{ presentationSessionId = sessionId },
		Types.Limits.MaxEvidence
	)
	return { ok = true, code = "Ok", session = transitioned.session }
end

function Queue.dequeue()
	local sessionId = table.remove(queued, 1)
	if sessionId == nil then
		return { ok = true, code = "Ok", empty = true }
	end
	Metrics.increment("queueOperations")
	return { ok = true, code = "Ok", sessionId = sessionId, session = Sessions.get(sessionId) }
end

function Queue.assign(sessionId: string)
	removeFrom(queued, sessionId)
	local transitioned = Lifecycle.transition(sessionId, Types.RuntimeSessionState.Assigned)
	if not transitioned.ok then
		return transitioned
	end
	assigned[#assigned + 1] = sessionId
	Metrics.increment("sessionsAssigned")
	Metrics.increment("queueOperations")
	Evidence.record(
		"PresentationSessionAssigned",
		{ presentationSessionId = sessionId },
		Types.Limits.MaxEvidence
	)
	return transitioned
end

function Queue.suspend(sessionId: string)
	removeFrom(assigned, sessionId)
	local transitioned = Lifecycle.transition(sessionId, Types.RuntimeSessionState.Suspended)
	if not transitioned.ok then
		return transitioned
	end
	suspended[#suspended + 1] = sessionId
	Metrics.increment("queueOperations")
	return transitioned
end

function Queue.resume(sessionId: string)
	removeFrom(suspended, sessionId)
	return Queue.assign(sessionId)
end

function Queue.cancel(sessionId: string)
	removeFrom(queued, sessionId)
	removeFrom(assigned, sessionId)
	removeFrom(suspended, sessionId)
	local transitioned = Lifecycle.transition(sessionId, Types.RuntimeSessionState.Cancelled)
	if not transitioned.ok then
		return transitioned
	end
	cancelled[#cancelled + 1] = sessionId
	Metrics.increment("queueOperations")
	Evidence.record(
		"PresentationSessionCancelled",
		{ presentationSessionId = sessionId },
		Types.Limits.MaxEvidence
	)
	return transitioned
end

function Queue.inspect()
	return Serialization.deepCopy({
		queued = queued,
		assigned = assigned,
		suspended = suspended,
		cancelled = cancelled,
	})
end

function Queue.clear()
	table.clear(queued)
	table.clear(assigned)
	table.clear(suspended)
	table.clear(cancelled)
end

return Queue

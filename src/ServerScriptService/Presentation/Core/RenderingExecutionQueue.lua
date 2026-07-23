--!strict

local Evidence = require(script.Parent.RenderingExecutionEvidence)
local Lifecycle = require(script.Parent.RenderingExecutionLifecycle)
local Metrics = require(script.Parent.RenderingExecutionMetrics)
local Serialization = require(script.Parent.PresentationSerialization)
local Sessions = require(script.Parent.RenderingExecutionSessionRegistry)
local Types = require(script.Parent.PresentationTypes)

local Queue = {}
local queued = {}
local suspended = {}

local function remove(list: { string }, value: string)
	for index, item in ipairs(list) do
		if item == value then
			table.remove(list, index)
			return
		end
	end
end

local function sortQueued()
	table.sort(queued, function(leftId, rightId)
		local left = Sessions.get(leftId)
		local right = Sessions.get(rightId)
		if left.runtimePriority ~= right.runtimePriority then
			return left.runtimePriority > right.runtimePriority
		end
		if left.assignmentPriority ~= right.assignmentPriority then
			return left.assignmentPriority > right.assignmentPriority
		end
		if left.queueOrdinal ~= right.queueOrdinal then
			return left.queueOrdinal < right.queueOrdinal
		end
		return left.renderingExecutionSessionId < right.renderingExecutionSessionId
	end)
end

function Queue.enqueue(sessionId: string)
	if #queued >= Types.RenderingExecutionLimits.MaxQueuedSessions then
		return {
			ok = false,
			code = Types.RenderingExecutionFailureType.QueueOverflow,
			message = "rendering execution queue overflow",
		}
	end
	local transition = Lifecycle.transition(sessionId, Types.RenderingExecutionState.Queued)
	if not transition.ok then
		return transition
	end
	queued[#queued + 1] = sessionId
	sortQueued()
	Metrics.increment("queuedSessions")
	Evidence.record("execution queued", { renderingExecutionSessionId = sessionId })
	return { ok = true, code = "Ok", queue = Serialization.deepCopy(queued) }
end

function Queue.dequeue()
	sortQueued()
	local sessionId = table.remove(queued, 1)
	if sessionId == nil then
		return { ok = true, code = "Empty" }
	end
	return { ok = true, code = "Ok", renderingExecutionSessionId = sessionId }
end

function Queue.suspend(sessionId: string)
	remove(queued, sessionId)
	local transition = Lifecycle.transition(sessionId, Types.RenderingExecutionState.Suspended)
	if not transition.ok then
		return transition
	end
	suspended[#suspended + 1] = sessionId
	Metrics.increment("suspensionCount")
	Evidence.record("execution suspended", { renderingExecutionSessionId = sessionId })
	return { ok = true, code = "Ok" }
end

function Queue.resume(sessionId: string)
	remove(suspended, sessionId)
	local transition = Lifecycle.transition(sessionId, Types.RenderingExecutionState.Queued)
	if not transition.ok then
		return transition
	end
	queued[#queued + 1] = sessionId
	sortQueued()
	Metrics.increment("resumeCount")
	Evidence.record("execution resumed", { renderingExecutionSessionId = sessionId })
	return { ok = true, code = "Ok" }
end

function Queue.inspect()
	return { queued = Serialization.deepCopy(queued), suspended = Serialization.deepCopy(suspended) }
end

function Queue.clear()
	table.clear(queued)
	table.clear(suspended)
end

return Queue

--!strict

local Evidence = require(script.Parent.InteractionEvidence)
local Metrics = require(script.Parent.InteractionMetrics)
local Serialization = require(script.Parent.DialogueSerialization)
local Types = require(script.Parent.DialogueInteractionTypes)

local Queue = {}
local pending = {}

function Queue.enqueue(session: any)
	if #pending >= Types.Limits.MaxPendingInteractions then
		return {
			ok = false,
			code = Types.FailureType.LimitExceeded,
			message = "pending queue limit exceeded",
		}
	end
	pending[#pending + 1] = {
		interactionId = session.interactionId,
		executionId = session.executionId,
		priority = session.priority or 0,
		order = #pending + 1,
	}
	table.sort(pending, function(left, right)
		if left.priority == right.priority then
			return left.order < right.order
		end
		return left.priority > right.priority
	end)
	Metrics.increment("queueOperations")
	Evidence.record("interaction waiting", { interactionId = session.interactionId })
	return { ok = true, code = "Ok" }
end

function Queue.remove(interactionId: string)
	for index, item in ipairs(pending) do
		if item.interactionId == interactionId then
			table.remove(pending, index)
			Metrics.increment("queueOperations")
			return { ok = true, code = "Ok" }
		end
	end
	return {
		ok = false,
		code = Types.FailureType.UnknownInteraction,
		message = "interaction not queued",
	}
end

function Queue.inspect()
	return Serialization.deepCopy(pending)
end

function Queue.clear()
	table.clear(pending)
end

return Queue

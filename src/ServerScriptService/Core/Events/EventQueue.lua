--!strict

local Evidence = require(script.Parent.EventEvidence)
local Serialization = require(script.Parent.EventSerialization)
local Types = require(script.Parent.EventTypes)

local Queue = {}
local buckets: { [string]: { any } } = {
	Critical = {},
	High = {},
	Normal = {},
	Low = {},
}
local ids: { [string]: boolean } = {}
local maxDepth = 0

local order = { "Critical", "High", "Normal", "Low" }

local function depth(): number
	local count = 0
	for _, priority in ipairs(order) do
		count += #buckets[priority]
	end
	return count
end

function Queue.enqueue(envelope: any)
	if ids[envelope.eventId] then
		return {
			ok = false,
			code = Types.FailureType.DuplicateEventId,
			message = "duplicate event id",
		}
	end
	if depth() >= Types.Limits.MaxQueueDepth then
		Evidence.record("queue overflow", { eventId = envelope.eventId })
		return { ok = false, code = Types.FailureType.QueueFull, message = "event queue is full" }
	end
	local priority = envelope.priority or Types.Priority.Normal
	if buckets[priority] == nil then
		return { ok = false, code = Types.FailureType.InvalidPriority, message = "invalid priority" }
	end
	table.insert(buckets[priority], Serialization.deepCopy(envelope))
	ids[envelope.eventId] = true
	maxDepth = math.max(maxDepth, depth())
	Evidence.record("event queued", { eventId = envelope.eventId, priority = priority })
	return { ok = true, code = "Ok", depth = depth() }
end

function Queue.dequeue(): any?
	for _, priority in ipairs(order) do
		local bucket = buckets[priority]
		if #bucket > 0 then
			local envelope = table.remove(bucket, 1)
			ids[envelope.eventId] = nil
			return Serialization.deepCopy(envelope)
		end
	end
	return nil
end

function Queue.peek(): any?
	for _, priority in ipairs(order) do
		if #buckets[priority] > 0 then
			return Serialization.deepCopy(buckets[priority][1])
		end
	end
	return nil
end

function Queue.cancelQueued(eventId: string)
	for _, priority in ipairs(order) do
		local bucket = buckets[priority]
		for index, envelope in ipairs(bucket) do
			if envelope.eventId == eventId then
				table.remove(bucket, index)
				ids[eventId] = nil
				Evidence.record("event cancelled", { eventId = eventId })
				return { ok = true, code = "Ok" }
			end
		end
	end
	return {
		ok = false,
		code = Types.FailureType.CancellationRejected,
		message = "event is not queued",
	}
end

function Queue.getDepth(): number
	return depth()
end

function Queue.getCapacity(): number
	return Types.Limits.MaxQueueDepth
end

function Queue.getMaximumDepth(): number
	return maxDepth
end

function Queue.inspect()
	local snapshot = {
		depth = depth(),
		capacity = Types.Limits.MaxQueueDepth,
		maximumDepth = maxDepth,
		buckets = {},
	}
	for _, priority in ipairs(order) do
		snapshot.buckets[priority] = Serialization.copyArray(buckets[priority])
	end
	return Serialization.deepCopy(snapshot)
end

function Queue.clear()
	for _, priority in ipairs(order) do
		table.clear(buckets[priority])
	end
	table.clear(ids)
	maxDepth = 0
end

return Queue

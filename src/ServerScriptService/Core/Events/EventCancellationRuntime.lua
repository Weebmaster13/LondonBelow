--!strict

local Queue = require(script.Parent.EventQueue)
local Serialization = require(script.Parent.EventSerialization)
local Types = require(script.Parent.EventTypes)

local Cancellation = {}
local cancelled: { [string]: any } = {}

function Cancellation.requestCancellation(eventId: string)
	local result = Queue.cancelQueued(eventId)
	if result.ok then
		cancelled[eventId] = { eventId = eventId, status = Types.Status.Cancelled }
	end
	return Serialization.deepCopy(result)
end

function Cancellation.canCancel(eventId: string): boolean
	local queued = Queue.inspect()
	for _, bucket in pairs(queued.buckets) do
		for _, envelope in ipairs(bucket) do
			if envelope.eventId == eventId then
				return true
			end
		end
	end
	return false
end

Cancellation.cancelCreated = Cancellation.requestCancellation
Cancellation.cancelValidated = Cancellation.requestCancellation
Cancellation.cancelQueued = Cancellation.requestCancellation

function Cancellation.inspectCancellation()
	return Serialization.deepCopy(cancelled)
end

function Cancellation.clear()
	table.clear(cancelled)
end

return Cancellation

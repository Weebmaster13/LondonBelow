--!strict

local Serialization = require(script.Parent.EventSerialization)

local ReplaySafety = {}

function ReplaySafety.metadata(envelope: any, definition: any)
	return Serialization.deepCopy({
		eventId = envelope.eventId,
		eventType = envelope.eventType,
		replayPolicy = definition.replayPolicy,
		replaySafe = definition.replayPolicy == "ReplaySafe",
		replayExecutor = false,
	})
end

return ReplaySafety

--!strict

local Evidence = require(script.Parent.InteractionEvidence)
local Metrics = require(script.Parent.InteractionMetrics)
local PendingQueue = require(script.Parent.PendingChoiceQueue)
local Registry = require(script.Parent.InteractionSessionRegistry)
local Serialization = require(script.Parent.DialogueSerialization)
local Types = require(script.Parent.DialogueInteractionTypes)

local TimeoutManager = {}
local records = {}

function TimeoutManager.expire(interactionId: string, reason: string)
	local session = Registry.get(interactionId)
	if session == nil then
		return {
			ok = false,
			code = Types.FailureType.UnknownInteraction,
			message = "unknown interaction",
		}
	end
	PendingQueue.remove(interactionId)
	Registry.update(
		interactionId,
		{ status = Types.InteractionStatus.Expired, timeoutReason = reason }
	)
	Registry.update(interactionId, { status = Types.InteractionStatus.Closed })
	records[#records + 1] = { interactionId = interactionId, reason = reason }
	Metrics.increment("timeouts")
	Evidence.record("interaction expired", { interactionId = interactionId, reason = reason })
	return { ok = true, code = "Ok" }
end

function TimeoutManager.inspect()
	return Serialization.deepCopy(records)
end

function TimeoutManager.clear()
	table.clear(records)
end

return TimeoutManager

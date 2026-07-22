--!strict

local Evidence = require(script.Parent.InteractionEvidence)
local Metrics = require(script.Parent.InteractionMetrics)
local Serialization = require(script.Parent.DialogueSerialization)
local Types = require(script.Parent.DialogueInteractionTypes)

local Nested = {}
local records = {}

function Nested.enter(
	parentExecutionId: string,
	childExecutionId: string,
	returnTarget: string,
	depth: number
)
	if
		#records >= Types.Limits.MaxNestedConversations
		or depth > Types.Limits.MaxNestedConversations
	then
		return {
			ok = false,
			code = Types.FailureType.LimitExceeded,
			message = "nested conversation limit exceeded",
		}
	end
	records[#records + 1] = {
		parentExecutionId = parentExecutionId,
		childExecutionId = childExecutionId,
		returnTarget = returnTarget,
		depth = depth,
		status = "Entered",
	}
	Metrics.increment("nestedConversations")
	Evidence.record("nested conversation entered", {
		parentExecutionId = parentExecutionId,
		childExecutionId = childExecutionId,
		returnTarget = returnTarget,
		depth = depth,
	})
	return { ok = true, code = "Ok" }
end

function Nested.exit(childExecutionId: string)
	for _, record in ipairs(records) do
		if record.childExecutionId == childExecutionId and record.status == "Entered" then
			record.status = "Exited"
			Evidence.record("nested conversation exited", { childExecutionId = childExecutionId })
			return { ok = true, code = "Ok" }
		end
	end
	return {
		ok = false,
		code = Types.FailureType.InvalidNestedConversation,
		message = "nested conversation not active",
	}
end

function Nested.inspect()
	return Serialization.deepCopy(records)
end

function Nested.clear()
	table.clear(records)
end

return Nested

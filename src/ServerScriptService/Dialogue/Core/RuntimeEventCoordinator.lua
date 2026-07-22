--!strict

local Evidence = require(script.Parent.InteractionEvidence)
local Metrics = require(script.Parent.InteractionMetrics)
local Serialization = require(script.Parent.DialogueSerialization)
local Types = require(script.Parent.DialogueInteractionTypes)

local RuntimeEvents = {}
local queue = {}

local function hasKind(kind: string): boolean
	for _, value in pairs(Types.RuntimeEventKind) do
		if value == kind then
			return true
		end
	end
	return false
end

function RuntimeEvents.enqueue(kind: string, executionId: string, payload: any?)
	if not hasKind(kind) then
		return {
			ok = false,
			code = Types.FailureType.ValidationFailure,
			message = "unsupported runtime event kind",
		}
	end
	if #queue >= Types.Limits.MaxRuntimeEvents then
		return {
			ok = false,
			code = Types.FailureType.LimitExceeded,
			message = "runtime event limit exceeded",
		}
	end
	queue[#queue + 1] = {
		eventId = string.format("dialogue.interaction.event.%06d", #queue + 1),
		kind = kind,
		executionId = executionId,
		payload = Serialization.deepCopy(payload or {}),
		order = #queue + 1,
	}
	Metrics.increment("queueOperations")
	Evidence.record("runtime event queued", { kind = kind, executionId = executionId })
	return { ok = true, code = "Ok" }
end

function RuntimeEvents.inspect()
	return Serialization.deepCopy(queue)
end

function RuntimeEvents.clear()
	table.clear(queue)
end

return RuntimeEvents

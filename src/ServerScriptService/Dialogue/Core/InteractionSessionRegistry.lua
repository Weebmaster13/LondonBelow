--!strict

local Evidence = require(script.Parent.InteractionEvidence)
local Metrics = require(script.Parent.InteractionMetrics)
local Serialization = require(script.Parent.DialogueSerialization)
local Types = require(script.Parent.DialogueInteractionTypes)

local Registry = {}
local sessions = {}
local order = {}
local nextOrdinal = 0

function Registry.create(request: any)
	if #order >= Types.Limits.MaxPendingInteractions then
		return {
			ok = false,
			code = Types.FailureType.LimitExceeded,
			message = "interaction limit exceeded",
		}
	end
	if type(request) ~= "table" then
		return {
			ok = false,
			code = Types.FailureType.ValidationFailure,
			message = "request must be a table",
		}
	end
	for _, field in ipairs({
		"interactionId",
		"executionId",
		"conversationId",
		"currentNodeId",
		"expectedResponse",
	}) do
		if type(request[field]) ~= "string" or request[field] == "" then
			return {
				ok = false,
				code = Types.FailureType.ValidationFailure,
				message = "invalid field " .. field,
			}
		end
	end
	if sessions[request.interactionId] ~= nil then
		return {
			ok = false,
			code = Types.FailureType.DuplicateInteraction,
			message = "duplicate interaction",
		}
	end
	nextOrdinal += 1
	local session = {
		interactionId = request.interactionId,
		executionId = request.executionId,
		conversationId = request.conversationId,
		currentNodeId = request.currentNodeId,
		expectedResponse = request.expectedResponse,
		createdTime = nextOrdinal,
		expirationTime = nextOrdinal + (request.timeoutDuration or 0),
		priority = request.priority or 0,
		status = Types.InteractionStatus.Created,
		response = nil :: any?,
		metadata = Serialization.deepCopy(request.metadata or {}),
	}
	sessions[request.interactionId] = session
	order[#order + 1] = request.interactionId
	Metrics.increment("interactionsCreated")
	Evidence.record("interaction requested", { interactionId = request.interactionId })
	return { ok = true, code = "Ok", session = Serialization.deepCopy(session) }
end

function Registry.get(interactionId: string): any?
	local session = sessions[interactionId]
	return if session then Serialization.deepCopy(session) else nil
end

function Registry.update(interactionId: string, patch: any)
	local session = sessions[interactionId]
	if session == nil then
		return {
			ok = false,
			code = Types.FailureType.UnknownInteraction,
			message = "unknown interaction",
		}
	end
	for key, value in pairs(patch) do
		session[key] = Serialization.deepCopy(value)
	end
	Evidence.record("interaction status changed", {
		interactionId = interactionId,
		status = session.status,
	})
	return { ok = true, code = "Ok", session = Serialization.deepCopy(session) }
end

function Registry.inspect()
	local result = {}
	for index, interactionId in ipairs(order) do
		result[index] = Serialization.deepCopy(sessions[interactionId])
	end
	return result
end

function Registry.clear()
	table.clear(sessions)
	table.clear(order)
	nextOrdinal = 0
end

return Registry

--!strict

local Evidence = require(script.Parent.PresentationEvidence)
local Metrics = require(script.Parent.PresentationMetrics)
local Serialization = require(script.Parent.PresentationSerialization)
local Types = require(script.Parent.PresentationTypes)

local Registry = {}
local sessions = {}
local order = {}
local nextOrdinal = 0

function Registry.create(request: any)
	if #order >= Types.Limits.MaxRuntimeSessions then
		return {
			ok = false,
			code = Types.RuntimeFailureType.LimitExceeded,
			message = "session limit exceeded",
		}
	end
	if type(request) ~= "table" then
		return {
			ok = false,
			code = Types.RuntimeFailureType.ValidationFailure,
			message = "session request must be a table",
		}
	end
	for _, field in ipairs({
		"presentationSessionId",
		"presentationId",
		"executionId",
		"consumerId",
		"descriptorReference",
		"synchronizationReference",
	}) do
		if type(request[field]) ~= "string" or request[field] == "" then
			return {
				ok = false,
				code = Types.RuntimeFailureType.ValidationFailure,
				message = "invalid field " .. field,
			}
		end
	end
	if sessions[request.presentationSessionId] ~= nil then
		return {
			ok = false,
			code = Types.RuntimeFailureType.DuplicateSession,
			message = "duplicate session",
		}
	end
	nextOrdinal += 1
	local session = {
		presentationSessionId = request.presentationSessionId,
		presentationId = request.presentationId,
		executionId = request.executionId,
		consumerId = request.consumerId,
		descriptorReference = request.descriptorReference,
		synchronizationReference = request.synchronizationReference,
		queueOrdinal = nextOrdinal,
		priority = request.priority or 0,
		lifecycleState = Types.RuntimeSessionState.Created,
		runtimeMetadata = Serialization.deepCopy(request.runtimeMetadata or {}),
	}
	sessions[session.presentationSessionId] = session
	order[#order + 1] = session.presentationSessionId
	Metrics.increment("sessionsCreated")
	Evidence.record(
		"PresentationSessionCreated",
		{ presentationSessionId = session.presentationSessionId },
		Types.Limits.MaxEvidence
	)
	return { ok = true, code = "Ok", session = Serialization.deepCopy(session) }
end

function Registry.get(sessionId: string)
	local session = sessions[sessionId]
	return if session then Serialization.deepCopy(session) else nil
end

function Registry.update(sessionId: string, patch: any)
	local session = sessions[sessionId]
	if session == nil then
		return {
			ok = false,
			code = Types.RuntimeFailureType.UnknownSession,
			message = "unknown session",
		}
	end
	for key, value in pairs(patch) do
		session[key] = Serialization.deepCopy(value)
	end
	return { ok = true, code = "Ok", session = Serialization.deepCopy(session) }
end

function Registry.inspect()
	local result = {}
	for index, sessionId in ipairs(order) do
		result[index] = Serialization.deepCopy(sessions[sessionId])
	end
	return result
end

function Registry.clear()
	table.clear(sessions)
	table.clear(order)
	nextOrdinal = 0
end

return Registry

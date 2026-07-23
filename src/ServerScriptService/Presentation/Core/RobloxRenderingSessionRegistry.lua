--!strict

local Evidence = require(script.Parent.RobloxRenderingSessionEvidence)
local Metrics = require(script.Parent.RobloxRenderingSessionMetrics)
local Serialization = require(script.Parent.PresentationSerialization)
local Types = require(script.Parent.PresentationTypes)

local Registry = {}
local sessions = {}
local order = {}
local nextOrdinal = 0

local allowedFields = {
	robloxRenderingSessionId = true,
	renderingExecutionSessionId = true,
	renderingSessionId = true,
	rendererId = true,
	owner = true,
	runtimePriority = true,
	runtimeMetadata = true,
}

local function validString(value: any): boolean
	return type(value) == "string" and value ~= ""
end

function Registry.create(input: any)
	if #order >= Types.RobloxRenderingSessionLimits.MaxSessions then
		return {
			ok = false,
			code = Types.RobloxRenderingSessionFailureType.LimitExceeded,
			message = "session limit exceeded",
		}
	end
	if type(input) ~= "table" then
		return {
			ok = false,
			code = Types.RobloxRenderingSessionFailureType.ValidationFailure,
			message = "session input must be a table",
		}
	end
	for field in pairs(input) do
		if not allowedFields[field] then
			return {
				ok = false,
				code = Types.RobloxRenderingSessionFailureType.ValidationFailure,
				message = "invalid field " .. field,
			}
		end
	end
	for _, field in ipairs({
		"robloxRenderingSessionId",
		"renderingExecutionSessionId",
		"renderingSessionId",
		"rendererId",
		"owner",
	}) do
		if not validString(input[field]) then
			return {
				ok = false,
				code = Types.RobloxRenderingSessionFailureType.ValidationFailure,
				message = "invalid field " .. field,
			}
		end
	end
	if sessions[input.robloxRenderingSessionId] ~= nil then
		return {
			ok = false,
			code = Types.RobloxRenderingSessionFailureType.DuplicateSession,
			message = "duplicate Roblox rendering session",
		}
	end
	local serializable, reason = Serialization.validateSerializable(input.runtimeMetadata or {})
	if not serializable then
		return {
			ok = false,
			code = Types.RobloxRenderingSessionFailureType.ValidationFailure,
			message = reason,
		}
	end
	nextOrdinal += 1
	local session = {
		robloxRenderingSessionId = input.robloxRenderingSessionId,
		renderingExecutionSessionId = input.renderingExecutionSessionId,
		renderingSessionId = input.renderingSessionId,
		rendererId = input.rendererId,
		platform = Types.RobloxRenderingPlatform,
		owner = input.owner,
		sessionState = Types.RobloxRenderingSessionState.Created,
		reservationState = Types.RobloxRendererReservationState.None,
		schedulingState = Types.RobloxRendererSchedulingState.Created,
		lifecycleState = Types.RobloxRenderingSessionState.Created,
		runtimePriority = input.runtimePriority or 0,
		runtimeMetadata = Serialization.deepCopy(input.runtimeMetadata or {}),
		creationOrdinal = nextOrdinal,
		queueOrdinal = 0,
		schedulerOrdinal = 0,
		dispatchEligibility = false,
	}
	sessions[session.robloxRenderingSessionId] = session
	order[#order + 1] = session.robloxRenderingSessionId
	Metrics.increment("activeRendererSessions")
	Evidence.record("session created", session)
	return { ok = true, code = "Ok", session = Serialization.deepCopy(session) }
end

function Registry.get(sessionId: string)
	local session = sessions[sessionId]
	if session == nil then
		return nil
	end
	return Serialization.deepCopy(session)
end

function Registry.update(sessionId: string, patch: any)
	local session = sessions[sessionId]
	if session == nil then
		return {
			ok = false,
			code = Types.RobloxRenderingSessionFailureType.UnknownSession,
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
	for index, id in ipairs(order) do
		result[index] = Serialization.deepCopy(sessions[id])
	end
	return result
end

function Registry.clear()
	table.clear(sessions)
	table.clear(order)
	nextOrdinal = 0
end

return Registry

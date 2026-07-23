--!strict

local Evidence = require(script.Parent.RenderingExecutionEvidence)
local Serialization = require(script.Parent.PresentationSerialization)
local Types = require(script.Parent.PresentationTypes)

local Registry = {}
local sessions = {}
local order = {}
local nextOrdinal = 0

local function validString(value: any): boolean
	return type(value) == "string" and value ~= ""
end

function Registry.create(input: any)
	if #order >= Types.RenderingExecutionLimits.MaxExecutionSessions then
		return {
			ok = false,
			code = Types.RenderingExecutionFailureType.LimitExceeded,
			message = "execution session limit exceeded",
		}
	end
	if type(input) ~= "table" then
		return {
			ok = false,
			code = Types.RenderingExecutionFailureType.ValidationFailure,
			message = "execution input must be a table",
		}
	end
	for _, field in ipairs({
		"renderingExecutionSessionId",
		"renderingSessionId",
		"renderingRequestId",
		"rendererId",
	}) do
		if not validString(input[field]) then
			return {
				ok = false,
				code = Types.RenderingExecutionFailureType.ValidationFailure,
				message = "invalid field " .. field,
			}
		end
	end
	if sessions[input.renderingExecutionSessionId] ~= nil then
		return {
			ok = false,
			code = Types.RenderingExecutionFailureType.DuplicateExecutionSession,
			message = "duplicate execution session",
		}
	end
	nextOrdinal += 1
	local session = {
		renderingExecutionSessionId = input.renderingExecutionSessionId,
		renderingSessionId = input.renderingSessionId,
		renderingRequestId = input.renderingRequestId,
		rendererId = input.rendererId,
		schedulerState = Types.RenderingExecutionSchedulerState.Idle,
		executionState = Types.RenderingExecutionState.Created,
		queueOrdinal = nextOrdinal,
		executionOrdinal = 0,
		runtimePriority = tonumber(input.runtimePriority) or 0,
		assignmentPriority = tonumber(input.assignmentPriority) or 0,
		runtimeMetadata = Serialization.deepCopy(input.runtimeMetadata or {}),
	}
	sessions[session.renderingExecutionSessionId] = session
	order[#order + 1] = session.renderingExecutionSessionId
	Evidence.record("execution session created", session)
	return { ok = true, code = "Ok", session = Serialization.deepCopy(session) }
end

function Registry.update(sessionId: string, patch: any)
	local session = sessions[sessionId]
	if session == nil then
		return {
			ok = false,
			code = Types.RenderingExecutionFailureType.UnknownExecutionSession,
			message = "unknown execution session",
		}
	end
	for key, value in pairs(patch) do
		session[key] = value
	end
	return { ok = true, code = "Ok", session = Serialization.deepCopy(session) }
end

function Registry.get(sessionId: string)
	return Serialization.deepCopy(sessions[sessionId])
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

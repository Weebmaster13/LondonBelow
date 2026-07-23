--!strict

local Evidence = require(script.Parent.RenderingRuntimeEvidence)
local Metrics = require(script.Parent.RenderingRuntimeMetrics)
local Serialization = require(script.Parent.PresentationSerialization)
local Types = require(script.Parent.PresentationTypes)

local Registry = {}
local sessions = {}
local order = {}
local nextOrdinal = 0

local function validString(value: any): boolean
	return type(value) == "string" and value ~= ""
end

function Registry.create(request: any)
	if #order >= Types.RenderingRuntimeLimits.MaxRenderingSessions then
		return {
			ok = false,
			code = Types.RenderingRuntimeFailureType.LimitExceeded,
			message = "rendering session limit exceeded",
		}
	end
	if type(request) ~= "table" then
		return {
			ok = false,
			code = Types.RenderingRuntimeFailureType.InvalidRenderingRequest,
			message = "request must be a table",
		}
	end
	for _, field in ipairs({
		"renderingSessionId",
		"renderingRequestId",
		"executionSessionId",
		"presentationSessionId",
		"renderingKind",
	}) do
		if not validString(request[field]) then
			return {
				ok = false,
				code = Types.RenderingRuntimeFailureType.InvalidRenderingRequest,
				message = "invalid field " .. field,
			}
		end
	end
	if sessions[request.renderingSessionId] ~= nil then
		return {
			ok = false,
			code = Types.RenderingRuntimeFailureType.DuplicateSession,
			message = "duplicate rendering session",
		}
	end
	if not Types.isRenderingKind(request.renderingKind) then
		return {
			ok = false,
			code = Types.RenderingRuntimeFailureType.InvalidRenderingRequest,
			message = "invalid rendering kind",
		}
	end
	nextOrdinal += 1
	local session = {
		renderingSessionId = request.renderingSessionId,
		renderingRequestId = request.renderingRequestId,
		executionSessionId = request.executionSessionId,
		presentationSessionId = request.presentationSessionId,
		rendererId = request.rendererId,
		renderingKind = request.renderingKind,
		descriptorVersion = request.descriptorVersion or "1.0.0",
		contractVersion = request.contractVersion or "1.0.0",
		synchronizationPolicy = request.synchronizationPolicy
			or Types.RenderingSynchronizationPolicy.NoWait,
		assignmentState = Types.RenderingRuntimeAssignmentState.Pending,
		lifecycleState = Types.RenderingRuntimeLifecycleState.Created,
		queueOrdinal = nextOrdinal,
		runtimePriority = tonumber(request.runtimePriority) or 0,
		runtimeMetadata = Serialization.deepCopy(request.runtimeMetadata or {}),
	}
	sessions[session.renderingSessionId] = session
	order[#order + 1] = session.renderingSessionId
	Metrics.increment("renderingSessions")
	Evidence.record("rendering session created", session)
	return { ok = true, code = "Ok", session = Serialization.deepCopy(session) }
end

function Registry.update(sessionId: string, patch: any)
	local session = sessions[sessionId]
	if session == nil then
		return {
			ok = false,
			code = Types.RenderingRuntimeFailureType.UnknownSession,
			message = "unknown rendering session",
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

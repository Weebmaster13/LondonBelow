--!strict

local Evidence = require(script.Parent.RobloxRenderingSessionEvidence)
local Metrics = require(script.Parent.RobloxRenderingSessionMetrics)
local Serialization = require(script.Parent.PresentationSerialization)
local Sessions = require(script.Parent.RobloxRenderingSessionRegistry)
local Types = require(script.Parent.PresentationTypes)

local Mapper = {}
local executionToRoblox = {}
local robloxToExecution = {}

function Mapper.map(sessionId: string)
	local session = Sessions.get(sessionId)
	if session == nil then
		return {
			ok = false,
			code = Types.RobloxRenderingSessionFailureType.UnknownSession,
			message = "unknown session",
		}
	end
	if executionToRoblox[session.renderingExecutionSessionId] ~= nil then
		return {
			ok = false,
			code = Types.RobloxRenderingSessionFailureType.DuplicateMapping,
			message = "duplicate execution mapping",
		}
	end
	if robloxToExecution[session.robloxRenderingSessionId] ~= nil then
		return {
			ok = false,
			code = Types.RobloxRenderingSessionFailureType.DuplicateMapping,
			message = "duplicate Roblox session mapping",
		}
	end
	executionToRoblox[session.renderingExecutionSessionId] = session.robloxRenderingSessionId
	robloxToExecution[session.robloxRenderingSessionId] = session.renderingExecutionSessionId
	Sessions.update(sessionId, {
		sessionState = Types.RobloxRenderingSessionState.Mapped,
		lifecycleState = Types.RobloxRenderingSessionState.Mapped,
	})
	Metrics.increment("mappedExecutionSessions")
	Evidence.record("execution session mapped", {
		robloxRenderingSessionId = session.robloxRenderingSessionId,
		renderingExecutionSessionId = session.renderingExecutionSessionId,
	})
	return { ok = true, code = "Ok" }
end

function Mapper.inspect()
	return Serialization.deepCopy({
		executionToRoblox = executionToRoblox,
		robloxToExecution = robloxToExecution,
	})
end

function Mapper.clear()
	table.clear(executionToRoblox)
	table.clear(robloxToExecution)
end

return Mapper

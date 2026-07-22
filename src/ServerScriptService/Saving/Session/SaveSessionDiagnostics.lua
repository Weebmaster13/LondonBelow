--!strict

local Serialization = require(script.Parent.SaveSessionSerialization)
local Types = require(script.Parent.SaveSessionTypes)
local Validation = require(script.Parent.SaveSessionValidation)

local Diagnostics = {}

function Diagnostics.capture(lifecycle: any, runtime: any)
	local inspected = runtime.inspect()
	local sessions = inspected.registry.sessions
	local activeSessions = 0
	local dirtySessions = 0
	local lockedSessions = 0
	for _, session in pairs(sessions) do
		if session.state ~= Types.State.Closed and session.state ~= Types.State.Cancelled then
			activeSessions += 1
		end
		if session.dirty then
			dirtySessions += 1
		end
		if session.lockOwner ~= nil then
			lockedSessions += 1
		end
	end
	return Serialization.deepCopy({
		saveSessionRuntimePosture = "Healthy",
		initialized = lifecycle.initialized,
		started = lifecycle.started,
		activeSessions = activeSessions,
		dirtySessions = dirtySessions,
		lockedSessions = lockedSessions,
		transactions = inspected.transactions.transactions,
		recoveries = inspected.recovery.recoveries,
		cancellations = inspected.cancellations,
		shutdowns = inspected.shutdowns,
		lastSelfChecks = lifecycle.lastSelfChecks,
		runtime = inspected,
	})
end

function Diagnostics.validate(): (boolean, string?)
	return Validation.validate()
end

return Diagnostics

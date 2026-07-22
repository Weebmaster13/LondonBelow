--!strict

local Evidence = require(script.Parent.SaveSessionEvidence)
local Serialization = require(script.Parent.SaveSessionSerialization)
local Types = require(script.Parent.SaveSessionTypes)
local Validation = require(script.Parent.SaveSessionValidation)

local Lifecycle = {}
local history: { any } = {}

local function remember(record: any)
	table.insert(history, Serialization.deepCopy(record))
	while #history > Types.Limits.MaxEvidence do
		table.remove(history, 1)
	end
end

function Lifecycle.transition(registry: any, sessionId: string, toState: string): (boolean, string?)
	local session = registry.get(sessionId)
	if session == nil then
		return false, "unknown session"
	end
	local ok, reason = Validation.transition(session.state, toState)
	if not ok then
		return false, reason
	end
	local fromState = session.state
	registry.update(sessionId, function(record)
		record.state = toState
		if toState == Types.State.Closed then
			record.dirty = false
		end
	end)
	local event = { sessionId = sessionId, fromState = fromState, toState = toState }
	remember(event)
	Evidence.record(if toState == Types.State.Closed then "session close" else "lifecycle", event)
	return true, nil
end

function Lifecycle.inspect()
	return { lifecycleSnapshot = Serialization.deepCopy(history), transitions = #history }
end

function Lifecycle.clear()
	table.clear(history)
end

return Lifecycle

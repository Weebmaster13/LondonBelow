--!strict

local Evidence = require(script.Parent.SaveSessionEvidence)
local Serialization = require(script.Parent.SaveSessionSerialization)
local Types = require(script.Parent.SaveSessionTypes)
local Validation = require(script.Parent.SaveSessionValidation)

local Registry = {}
local sessions: { [string]: any } = {}

local function countSessions(): number
	local count = 0
	for _ in pairs(sessions) do
		count += 1
	end
	return count
end

function Registry.create(definition: any): (boolean, string?, any?)
	local ok, reason = Validation.session(definition)
	if not ok then
		return false, reason, nil
	end
	if sessions[definition.sessionId] ~= nil then
		return false, "duplicate session", nil
	end
	if countSessions() >= Types.Limits.MaxSessions then
		return false, "session limit exceeded", nil
	end
	local session = {
		sessionId = definition.sessionId,
		saveId = definition.saveId,
		state = Types.State.New,
		provider = definition.provider or "memory",
		dirty = false,
		lockOwner = nil,
		activeTransaction = nil,
		retryCount = 0,
		openedTimestamp = definition.openedTimestamp or 0,
		lastSave = nil,
		lastLoad = nil,
		lastFailure = nil,
	}
	sessions[session.sessionId] = session
	Evidence.record("session open", { sessionId = session.sessionId, saveId = session.saveId })
	return true, nil, Serialization.freezeRecord(session)
end

function Registry.get(sessionId: string): any?
	return sessions[sessionId]
end

function Registry.update(sessionId: string, mutator: (any) -> ()): (boolean, string?)
	local session = sessions[sessionId]
	if session == nil then
		return false, "unknown session"
	end
	mutator(session)
	return true, nil
end

function Registry.remove(sessionId: string): (boolean, string?)
	if sessions[sessionId] == nil then
		return false, "unknown session"
	end
	sessions[sessionId] = nil
	return true, nil
end

function Registry.list()
	local ids = {}
	for id in pairs(sessions) do
		table.insert(ids, id)
	end
	table.sort(ids)
	return ids
end

function Registry.inspect()
	return {
		sessions = Serialization.deepCopy(sessions),
		ids = Registry.list(),
		count = countSessions(),
	}
end

function Registry.clear()
	table.clear(sessions)
end

return Registry

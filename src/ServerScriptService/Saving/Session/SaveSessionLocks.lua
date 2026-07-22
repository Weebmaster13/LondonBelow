--!strict

local Evidence = require(script.Parent.SaveSessionEvidence)
local Serialization = require(script.Parent.SaveSessionSerialization)

local Locks = {}
local history: { any } = {}

local function remember(kind: string, sessionId: string, owner: string?)
	local event = { sessionId = sessionId, owner = owner }
	table.insert(history, Serialization.deepCopy(event))
	Evidence.record(kind, event)
end

function Locks.acquire(registry: any, sessionId: string, owner: string): (boolean, string?)
	local session = registry.get(sessionId)
	if session == nil then
		return false, "unknown session"
	end
	if session.lockOwner ~= nil and session.lockOwner ~= owner then
		return false, "session already locked"
	end
	registry.update(sessionId, function(record)
		record.lockOwner = owner
	end)
	remember("lock acquire", sessionId, owner)
	return true, nil
end

function Locks.release(registry: any, sessionId: string, owner: string): (boolean, string?)
	local session = registry.get(sessionId)
	if session == nil then
		return false, "unknown session"
	end
	if session.lockOwner ~= owner then
		return false, "stale lock owner"
	end
	registry.update(sessionId, function(record)
		record.lockOwner = nil
	end)
	remember("lock release", sessionId, owner)
	return true, nil
end

function Locks.isLocked(registry: any, sessionId: string): boolean
	local session = registry.get(sessionId)
	return session ~= nil and session.lockOwner ~= nil
end

function Locks.owner(registry: any, sessionId: string): string?
	local session = registry.get(sessionId)
	return if session ~= nil then session.lockOwner else nil
end

function Locks.inspect()
	return { lockSnapshot = Serialization.deepCopy(history), locks = #history }
end

function Locks.clear()
	table.clear(history)
end

return Locks

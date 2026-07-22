--!strict

local Evidence = require(script.Parent.SaveSessionEvidence)
local Serialization = require(script.Parent.SaveSessionSerialization)

local Dirty = {}
local history: { any } = {}

local function record(sessionId: string, dirty: boolean)
	local event = { sessionId = sessionId, dirty = dirty }
	table.insert(history, Serialization.deepCopy(event))
	Evidence.record("dirty changes", event)
end

function Dirty.markDirty(registry: any, sessionId: string): (boolean, string?)
	local session = registry.get(sessionId)
	if session == nil then
		return false, "unknown session"
	end
	registry.update(sessionId, function(item)
		item.dirty = true
	end)
	record(sessionId, true)
	return true, nil
end

function Dirty.markClean(registry: any, sessionId: string): (boolean, string?)
	local session = registry.get(sessionId)
	if session == nil then
		return false, "unknown session"
	end
	registry.update(sessionId, function(item)
		item.dirty = false
	end)
	record(sessionId, false)
	return true, nil
end

function Dirty.isDirty(registry: any, sessionId: string): boolean
	local session = registry.get(sessionId)
	return session ~= nil and session.dirty == true
end

function Dirty.inspect()
	return { dirtyHistory = Serialization.deepCopy(history), dirtyChanges = #history }
end

function Dirty.clear()
	table.clear(history)
end

return Dirty

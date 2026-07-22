--!strict

local DirtyTracker = require(script.Parent.SaveSessionDirtyTracker)
local Evidence = require(script.Parent.SaveSessionEvidence)
local Lifecycle = require(script.Parent.SaveSessionLifecycle)
local Locks = require(script.Parent.SaveSessionLocks)
local Recovery = require(script.Parent.SaveSessionRecovery)
local Registry = require(script.Parent.SaveSessionRegistry)
local Serialization = require(script.Parent.SaveSessionSerialization)
local Transactions = require(script.Parent.SaveSessionTransactions)
local Types = require(script.Parent.SaveSessionTypes)

local Runtime = {}
local cancellations = 0
local shutdowns = 0

function Runtime.openSession(definition: any): (boolean, string?, any?)
	local ok, reason, session = Registry.create(definition)
	if not ok then
		return false, reason, nil
	end
	Lifecycle.transition(Registry, definition.sessionId, Types.State.Opening)
	Lifecycle.transition(Registry, definition.sessionId, Types.State.Active)
	return true, nil, session
end

function Runtime.closeSession(sessionId: string): (boolean, string?)
	local session = Registry.get(sessionId)
	if session == nil then
		return false, "unknown session"
	end
	if session.activeTransaction ~= nil then
		Transactions.commit(Registry, sessionId)
	end
	if session.lockOwner ~= nil then
		Registry.update(sessionId, function(record)
			record.lockOwner = nil
		end)
	end
	local closingOk, closingReason = Lifecycle.transition(Registry, sessionId, Types.State.Closing)
	if not closingOk then
		return false, closingReason
	end
	return Lifecycle.transition(Registry, sessionId, Types.State.Closed)
end

function Runtime.acquireLock(sessionId: string, owner: string)
	return Locks.acquire(Registry, sessionId, owner)
end

function Runtime.releaseLock(sessionId: string, owner: string)
	return Locks.release(Registry, sessionId, owner)
end

function Runtime.isLocked(sessionId: string)
	return Locks.isLocked(Registry, sessionId)
end

function Runtime.lockOwner(sessionId: string)
	return Locks.owner(Registry, sessionId)
end

function Runtime.beginTransaction(sessionId: string, transactionId: string)
	return Transactions.begin(Registry, sessionId, transactionId)
end

function Runtime.commitTransaction(sessionId: string)
	return Transactions.commit(Registry, sessionId)
end

function Runtime.rollbackTransaction(sessionId: string)
	return Transactions.rollback(Registry, sessionId)
end

function Runtime.cancelTransaction(sessionId: string)
	return Transactions.cancel(Registry, sessionId)
end

function Runtime.markDirty(sessionId: string): (boolean, string?)
	local ok, reason = DirtyTracker.markDirty(Registry, sessionId)
	if not ok then
		return false, reason
	end
	local session = Registry.get(sessionId)
	if session ~= nil and session.state == Types.State.Active then
		Lifecycle.transition(Registry, sessionId, Types.State.Dirty)
	end
	return true, nil
end

function Runtime.markClean(sessionId: string): (boolean, string?)
	return DirtyTracker.markClean(Registry, sessionId)
end

function Runtime.isDirty(sessionId: string): boolean
	return DirtyTracker.isDirty(Registry, sessionId)
end

function Runtime.markSaving(sessionId: string)
	return Lifecycle.transition(Registry, sessionId, Types.State.Saving)
end

function Runtime.markSaved(sessionId: string)
	local cleanOk, cleanReason = Runtime.markClean(sessionId)
	if not cleanOk then
		return false, cleanReason
	end
	return Lifecycle.transition(Registry, sessionId, Types.State.Active)
end

function Runtime.cancelSession(sessionId: string): (boolean, string?)
	local session = Registry.get(sessionId)
	if session == nil then
		return false, "unknown session"
	end
	if session.activeTransaction ~= nil then
		Transactions.cancel(Registry, sessionId)
	end
	Registry.update(sessionId, function(record)
		record.lockOwner = nil
	end)
	cancellations += 1
	Evidence.record("cancel", { sessionId = sessionId })
	return Lifecycle.transition(Registry, sessionId, Types.State.Cancelled)
end

function Runtime.failSession(sessionId: string, reason: string): (boolean, string?)
	local session = Registry.get(sessionId)
	if session == nil then
		return false, "unknown session"
	end
	Registry.update(sessionId, function(record)
		record.lastFailure = reason
	end)
	Evidence.record("failure", { sessionId = sessionId, reason = reason })
	return Lifecycle.transition(Registry, sessionId, Types.State.Failed)
end

function Runtime.recoverSession(sessionId: string): (boolean, string?)
	return Recovery.recover(Registry, Lifecycle, sessionId)
end

function Runtime.shutdown()
	for _, sessionId in ipairs(Registry.list()) do
		local session = Registry.get(sessionId)
		if session ~= nil and session.state ~= Types.State.Closed then
			if session.state == Types.State.Cancelled then
				Registry.update(sessionId, function(record)
					record.lockOwner = nil
					record.activeTransaction = nil
				end)
			else
				Runtime.closeSession(sessionId)
			end
		end
	end
	shutdowns += 1
	Evidence.record("shutdown", { shutdowns = shutdowns })
	Registry.clear()
	Lifecycle.clear()
	Locks.clear()
	Transactions.clear()
	DirtyTracker.clear()
	Recovery.clear()
end

function Runtime.inspect()
	return Serialization.deepCopy({
		registry = Registry.inspect(),
		lifecycle = Lifecycle.inspect(),
		locks = Locks.inspect(),
		transactions = Transactions.inspect(),
		dirty = DirtyTracker.inspect(),
		recovery = Recovery.inspect(),
		evidence = Evidence.inspect(),
		cancellations = cancellations,
		shutdowns = shutdowns,
	})
end

function Runtime.clear()
	Registry.clear()
	Lifecycle.clear()
	Locks.clear()
	Transactions.clear()
	DirtyTracker.clear()
	Recovery.clear()
	Evidence.clear()
	cancellations = 0
	shutdowns = 0
end

return Runtime

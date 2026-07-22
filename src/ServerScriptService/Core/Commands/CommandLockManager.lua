--!strict

local Evidence = require(script.Parent.CommandEvidence)
local Serialization = require(script.Parent.CommandSerialization)
local Types = require(script.Parent.CommandTypes)

local Locks = {}
local heldLocks: { [string]: string } = {}

function Locks.acquire(commandId: string, lockIds: { string })
	local sorted = table.clone(lockIds)
	table.sort(sorted)
	if #sorted > Types.Limits.MaxLocksPerCommand then
		return { ok = false, code = Types.FailureType.LockFailure, message = "lock limit exceeded" }
	end
	for _, lockId in ipairs(sorted) do
		if heldLocks[lockId] ~= nil and heldLocks[lockId] ~= commandId then
			Evidence.record("lock acquisition deferred", { commandId = commandId, lockId = lockId })
			return { ok = false, code = Types.FailureType.LockFailure, message = "lock held" }
		end
	end
	for _, lockId in ipairs(sorted) do
		heldLocks[lockId] = commandId
	end
	Evidence.record("locks acquired", { commandId = commandId, lockIds = sorted })
	return { ok = true, code = "Ok", lockIds = Serialization.copyArray(sorted) }
end

function Locks.release(commandId: string)
	for lockId, owner in pairs(heldLocks) do
		if owner == commandId then
			heldLocks[lockId] = nil
		end
	end
	Evidence.record("locks released", { commandId = commandId })
end

function Locks.inspect()
	return Serialization.deepCopy(heldLocks)
end

function Locks.clear()
	table.clear(heldLocks)
end

return Locks

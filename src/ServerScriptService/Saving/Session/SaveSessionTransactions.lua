--!strict

local Evidence = require(script.Parent.SaveSessionEvidence)
local Serialization = require(script.Parent.SaveSessionSerialization)
local Types = require(script.Parent.SaveSessionTypes)

local Transactions = {}
local history: { any } = {}

local function remember(kind: string, record: any)
	table.insert(history, Serialization.deepCopy(record))
	Evidence.record(kind, record)
end

function Transactions.begin(
	registry: any,
	sessionId: string,
	transactionId: string
): (boolean, string?)
	local session = registry.get(sessionId)
	if session == nil then
		return false, "unknown session"
	end
	if session.state == Types.State.Cancelled then
		return false, "cancelled session cannot begin transaction"
	end
	if session.activeTransaction ~= nil then
		return false, "nested transaction prohibited"
	end
	registry.update(sessionId, function(record)
		record.activeTransaction = {
			transactionId = transactionId,
			state = Types.TransactionState.Active,
		}
	end)
	remember("transaction begin", { sessionId = sessionId, transactionId = transactionId })
	return true, nil
end

function Transactions.commit(registry: any, sessionId: string): (boolean, string?)
	local session = registry.get(sessionId)
	if session == nil then
		return false, "unknown session"
	end
	if session.state == Types.State.Cancelled then
		return false, "cancelled session cannot commit"
	end
	if session.activeTransaction == nil then
		return false, "commit without transaction"
	end
	local transactionId = session.activeTransaction.transactionId
	registry.update(sessionId, function(record)
		record.activeTransaction = nil
	end)
	remember("commit", { sessionId = sessionId, transactionId = transactionId })
	return true, nil
end

function Transactions.rollback(registry: any, sessionId: string): (boolean, string?)
	local session = registry.get(sessionId)
	if session == nil then
		return false, "unknown session"
	end
	if session.activeTransaction == nil then
		return false, "rollback without transaction"
	end
	local transactionId = session.activeTransaction.transactionId
	registry.update(sessionId, function(record)
		record.activeTransaction = nil
	end)
	remember("rollback", { sessionId = sessionId, transactionId = transactionId })
	return true, nil
end

function Transactions.cancel(registry: any, sessionId: string): (boolean, string?)
	local session = registry.get(sessionId)
	if session == nil then
		return false, "unknown session"
	end
	local transactionId = if session.activeTransaction ~= nil
		then session.activeTransaction.transactionId
		else nil
	registry.update(sessionId, function(record)
		record.activeTransaction = nil
	end)
	remember("cancel", { sessionId = sessionId, transactionId = transactionId })
	return true, nil
end

function Transactions.inspect()
	return { transactionSnapshot = Serialization.deepCopy(history), transactions = #history }
end

function Transactions.clear()
	table.clear(history)
end

return Transactions

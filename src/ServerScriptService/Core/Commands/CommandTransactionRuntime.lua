--!strict

local Evidence = require(script.Parent.CommandEvidence)
local Serialization = require(script.Parent.CommandSerialization)
local Types = require(script.Parent.CommandTypes)

local Transactions = {}
local transactions: { [string]: any } = {}

function Transactions.begin(transactionId: string, commandIds: { string })
	if transactions[transactionId] ~= nil then
		return {
			ok = false,
			code = Types.FailureType.TransactionFailure,
			message = "duplicate transaction",
		}
	end
	transactions[transactionId] = Serialization.deepCopy({
		transactionId = transactionId,
		state = "Created",
		commandIds = commandIds,
		rollbackReason = nil,
	})
	Evidence.record("transaction created", { transactionId = transactionId })
	return { ok = true, code = "Ok" }
end

function Transactions.commit(transactionId: string)
	local transaction = transactions[transactionId]
	if transaction == nil then
		return {
			ok = false,
			code = Types.FailureType.TransactionFailure,
			message = "unknown transaction",
		}
	end
	transaction.state = "Committed"
	Evidence.record("transaction committed", { transactionId = transactionId })
	return { ok = true, code = "Ok" }
end

function Transactions.rollback(transactionId: string, reason: string)
	local transaction = transactions[transactionId]
	if transaction == nil then
		return {
			ok = false,
			code = Types.FailureType.RollbackFailure,
			message = "unknown transaction",
		}
	end
	transaction.state = "RolledBack"
	transaction.rollbackReason = reason
	Evidence.record("transaction rolled back", { transactionId = transactionId, reason = reason })
	return { ok = true, code = "Ok" }
end

function Transactions.inspect()
	return Serialization.deepCopy(transactions)
end

function Transactions.clear()
	table.clear(transactions)
end

return Transactions

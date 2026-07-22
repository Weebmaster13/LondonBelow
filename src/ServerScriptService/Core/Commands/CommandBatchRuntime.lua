--!strict

local Evidence = require(script.Parent.CommandEvidence)
local Serialization = require(script.Parent.CommandSerialization)

local Batch = {}
local batches: { [string]: any } = {}

function Batch.register(batchId: string, commandIds: { string })
	batches[batchId] = Serialization.deepCopy({
		batchId = batchId,
		commandIds = commandIds,
		state = "Registered",
	})
	Evidence.record("batch registered", { batchId = batchId, commandIds = commandIds })
	return { ok = true, code = "Ok" }
end

function Batch.inspect()
	return Serialization.deepCopy(batches)
end

function Batch.clear()
	table.clear(batches)
end

return Batch

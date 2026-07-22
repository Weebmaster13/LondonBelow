--!strict

local Evidence = require(script.Parent.CommandEvidence)
local Serialization = require(script.Parent.CommandSerialization)
local Types = require(script.Parent.CommandTypes)

local Queue = {}
local buckets: { [string]: { any } } = {
	Critical = {},
	High = {},
	Normal = {},
	Low = {},
}
local ids: { [string]: boolean } = {}
local maxDepth = 0
local order = { "Critical", "High", "Normal", "Low" }

local function depth(): number
	local count = 0
	for _, priority in ipairs(order) do
		count += #buckets[priority]
	end
	return count
end

function Queue.enqueue(command: any)
	if ids[command.commandId] then
		return {
			ok = false,
			code = Types.FailureType.DuplicateCommandId,
			message = "duplicate command id",
		}
	end
	if depth() >= Types.Limits.MaxQueueDepth then
		Evidence.record("queue full", { commandId = command.commandId })
		return { ok = false, code = Types.FailureType.QueueFull, message = "command queue is full" }
	end
	local priority = command.priority or Types.Priority.Normal
	if buckets[priority] == nil then
		return { ok = false, code = Types.FailureType.InvalidPriority, message = "invalid priority" }
	end
	table.insert(buckets[priority], Serialization.deepCopy(command))
	ids[command.commandId] = true
	maxDepth = math.max(maxDepth, depth())
	Evidence.record("command queued", { commandId = command.commandId, priority = priority })
	return { ok = true, code = "Ok", depth = depth() }
end

function Queue.dequeue(): any?
	for _, priority in ipairs(order) do
		local bucket = buckets[priority]
		if #bucket > 0 then
			local command = table.remove(bucket, 1)
			ids[command.commandId] = nil
			return Serialization.deepCopy(command)
		end
	end
	return nil
end

function Queue.cancelQueued(commandId: string)
	for _, priority in ipairs(order) do
		local bucket = buckets[priority]
		for index, command in ipairs(bucket) do
			if command.commandId == commandId then
				table.remove(bucket, index)
				ids[commandId] = nil
				Evidence.record("command cancelled", { commandId = commandId })
				return { ok = true, code = "Ok" }
			end
		end
	end
	return {
		ok = false,
		code = Types.FailureType.CancellationRejected,
		message = "command is not queued",
	}
end

function Queue.getDepth(): number
	return depth()
end

function Queue.getMaximumDepth(): number
	return maxDepth
end

function Queue.inspect()
	local snapshot = {
		depth = depth(),
		capacity = Types.Limits.MaxQueueDepth,
		maximumDepth = maxDepth,
		buckets = {},
	}
	for _, priority in ipairs(order) do
		snapshot.buckets[priority] = Serialization.copyArray(buckets[priority])
	end
	return Serialization.deepCopy(snapshot)
end

function Queue.clear()
	for _, priority in ipairs(order) do
		table.clear(buckets[priority])
	end
	table.clear(ids)
	maxDepth = 0
end

return Queue

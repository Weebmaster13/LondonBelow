--!strict

local Config = require(script.Parent.GameplayExecutionConfig)
local Copy = require(script.Parent.Parent.Core.GameplayCopy)

local GameplayExecutionQueue = {}

local queue: { any } = {}
local queuedById: { [string]: boolean } = {}
local counters = {
	enqueued = 0,
	dequeued = 0,
	rejectedFull = 0,
	duplicatesRejected = 0,
}

local function sortQueue()
	table.sort(queue, function(left, right)
		if left.priority == right.priority then
			return left.createdAt < right.createdAt
		end
		return left.priority > right.priority
	end)
end

function GameplayExecutionQueue.enqueue(request: any): (boolean, string?)
	if queuedById[request.executionId] then
		counters.duplicatesRejected += 1
		return false, "execution already queued"
	end
	if #queue >= Config.MaxQueueSize then
		counters.rejectedFull += 1
		return false, "execution queue is full"
	end
	table.insert(queue, Copy.dictionary(request))
	queuedById[request.executionId] = true
	counters.enqueued += 1
	sortQueue()
	return true, nil
end

function GameplayExecutionQueue.dequeue(): any?
	local request = table.remove(queue, 1)
	if request == nil then
		return nil
	end
	queuedById[request.executionId] = nil
	counters.dequeued += 1
	return request
end

function GameplayExecutionQueue.remove(executionId: string): boolean
	for index, request in ipairs(queue) do
		if request.executionId == executionId then
			table.remove(queue, index)
			queuedById[executionId] = nil
			return true
		end
	end
	return false
end

function GameplayExecutionQueue.expire(now: number): { any }
	local expired = {}
	local index = 1
	while index <= #queue do
		local request = queue[index]
		if request.expiresAt <= now then
			table.insert(expired, request)
			queuedById[request.executionId] = nil
			table.remove(queue, index)
		else
			index += 1
		end
	end
	return expired
end

function GameplayExecutionQueue.inspect()
	return {
		size = #queue,
		limit = Config.MaxQueueSize,
		queue = Copy.array(queue),
		counters = table.clone(counters),
	}
end

function GameplayExecutionQueue.clear()
	table.clear(queue)
	table.clear(queuedById)
	for key in pairs(counters) do
		counters[key] = 0
	end
end

return GameplayExecutionQueue

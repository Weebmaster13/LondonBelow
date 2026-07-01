--!strict
-- Bounded priority queue for orchestration requests.

local Config = require(script.Parent.Parent.Core.HorrorOrchestrationConfig)

local Queue = {}

local items: { any } = {}

function Queue.enqueue(request: any): (boolean, string?)
	if #items >= Config.MaxQueueSize then
		return false, "horror pressure queue is full"
	end
	table.insert(items, request)
	table.sort(items, function(left, right)
		if left.priority == right.priority then
			return left.createdAt < right.createdAt
		end
		return left.priority > right.priority
	end)
	return true, nil
end

function Queue.dequeue(): any?
	return table.remove(items, 1)
end

function Queue.expire(currentTime: number): { any }
	local expired = {}
	for index = #items, 1, -1 do
		if items[index].expiresAt <= currentTime then
			table.insert(expired, table.remove(items, index))
		end
	end
	return expired
end

function Queue.clear()
	table.clear(items)
end

function Queue.inspect()
	return {
		size = #items,
		limit = Config.MaxQueueSize,
		pending = table.clone(items),
	}
end

return Queue

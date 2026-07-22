--!strict

local Evidence = require(script.Parent.QueryEvidence)
local Lifecycle = require(script.Parent.QueryLifecycle)
local Serialization = require(script.Parent.QuerySerialization)
local Types = require(script.Parent.QueryTypes)

local Queue = {}
local buckets: { [string]: { any } } = { Critical = {}, High = {}, Normal = {}, Low = {} }
local ids: { [string]: boolean } = {}
local order = { "Critical", "High", "Normal", "Low" }
local maxDepth = 0

local function depth(): number
	local count = 0
	for _, priority in ipairs(order) do
		count += #buckets[priority]
	end
	return count
end

function Queue.enqueue(query: any)
	if ids[query.queryId] then
		return {
			ok = false,
			code = Types.FailureType.DuplicateQueryId,
			message = "duplicate query id",
		}
	end
	if depth() >= Types.Limits.MaxQueueDepth then
		return { ok = false, code = Types.FailureType.QueueFull, message = "query queue is full" }
	end
	local priority = query.priority or Types.Priority.Normal
	if buckets[priority] == nil then
		return { ok = false, code = Types.FailureType.InvalidPriority, message = "invalid priority" }
	end
	local queued, reason = Lifecycle.transition(query, Types.Status.Queued, "queuedTimestamp")
	if queued == nil then
		return { ok = false, code = Types.FailureType.QueueFailure, message = reason }
	end
	table.insert(buckets[priority], Serialization.deepCopy(queued))
	ids[query.queryId] = true
	maxDepth = math.max(maxDepth, depth())
	Evidence.record("query queued", { queryId = query.queryId, priority = priority })
	return { ok = true, code = "Ok", depth = depth() }
end

function Queue.dequeue(): any?
	for _, priority in ipairs(order) do
		local bucket = buckets[priority]
		if #bucket > 0 then
			local query = table.remove(bucket, 1)
			ids[query.queryId] = nil
			local dispatched, reason =
				Lifecycle.transition(query, Types.Status.Dispatched, "dispatchedTimestamp")
			if dispatched == nil then
				return {
					queryId = query.queryId,
					queryType = query.queryType,
					status = Types.Status.Failed,
					failureReason = reason,
				}
			end
			return Serialization.deepCopy(dispatched)
		end
	end
	return nil
end

function Queue.cancel(queryId: string)
	for _, priority in ipairs(order) do
		for index, query in ipairs(buckets[priority]) do
			if query.queryId == queryId then
				table.remove(buckets[priority], index)
				ids[queryId] = nil
				local cancelled, reason =
					Lifecycle.transition(query, Types.Status.Cancelled, "completedTimestamp")
				if cancelled == nil then
					return {
						ok = false,
						code = Types.FailureType.CancellationRejected,
						message = reason,
					}
				end
				return { ok = true, code = "Ok", query = cancelled }
			end
		end
	end
	return {
		ok = false,
		code = Types.FailureType.CancellationRejected,
		message = "query is not queued",
	}
end

function Queue.getDepth(): number
	return depth()
end

function Queue.getMaximumDepth(): number
	return maxDepth
end

function Queue.inspect()
	return Serialization.deepCopy({ depth = depth(), maximumDepth = maxDepth, buckets = buckets })
end

function Queue.clear()
	for _, priority in ipairs(order) do
		table.clear(buckets[priority])
	end
	table.clear(ids)
	maxDepth = 0
end

return Queue

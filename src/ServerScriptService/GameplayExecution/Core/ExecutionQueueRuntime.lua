--!strict
-- Bounded execution queue. Records dry-run states only.

local Serialization = require(script.Parent.ExecutionSerialization)
local Types = require(script.Parent.ExecutionTypes)

local QueueRuntime = {}

local queue: { any } = {}
local statusCounts = {
	pending = 0,
	approved = 0,
	rejected = 0,
	cancelled = 0,
	expired = 0,
	dryRun = 0,
}

local function trimQueue()
	while #queue > Types.Limits.MaxQueue do
		table.remove(queue, 1)
	end
end

function QueueRuntime.enqueue(request: any): (boolean, string?)
	if #queue >= Types.Limits.MaxQueue then
		return false, "execution queue is full"
	end
	table.insert(queue, {
		executionId = request.executionId,
		status = Types.Status.Queued,
		priority = request.priority,
		createdAt = os.clock(),
		expiresAt = request.expiresAt,
		request = Serialization.deepCopy(request),
	})
	statusCounts.pending += 1
	trimQueue()
	return true, nil
end

function QueueRuntime.mark(status: string)
	if status == Types.Status.Approved then
		statusCounts.approved += 1
	elseif status == Types.Status.Rejected then
		statusCounts.rejected += 1
	elseif status == Types.Status.Cancelled then
		statusCounts.cancelled += 1
	elseif status == Types.Status.Expired then
		statusCounts.expired += 1
	elseif status == Types.Status.DryRun then
		statusCounts.dryRun += 1
	end
end

function QueueRuntime.inspect()
	return {
		queueCount = #queue,
		queue = Serialization.deepCopy(queue),
		pendingCount = statusCounts.pending,
		approvedCount = statusCounts.approved,
		rejectedCount = statusCounts.rejected,
		cancelledCount = statusCounts.cancelled,
		expiredCount = statusCounts.expired,
		dryRunCount = statusCounts.dryRun,
	}
end

function QueueRuntime.clear()
	table.clear(queue)
	statusCounts.pending = 0
	statusCounts.approved = 0
	statusCounts.rejected = 0
	statusCounts.cancelled = 0
	statusCounts.expired = 0
	statusCounts.dryRun = 0
end

return QueueRuntime

--!strict
-- Dry-run schedule records. This module never creates timers or gameplay tasks.

local Serialization = require(script.Parent.ExecutionSerialization)
local Types = require(script.Parent.ExecutionTypes)

local Scheduler = {}

local schedules: { any } = {}

local function trim()
	while #schedules > Types.Limits.MaxSchedules do
		table.remove(schedules, 1)
	end
end

function Scheduler.schedule(request: any)
	local record = {
		executionId = request.executionId,
		delaySeconds = math.max(0, request.expiresAt - os.clock()),
		priority = request.priority,
		expiresAt = request.expiresAt,
		status = Types.Status.Scheduled,
		cancelled = false,
		createdAt = os.clock(),
	}
	table.insert(schedules, record)
	trim()
	return Serialization.deepCopy(record)
end

function Scheduler.cancel(executionId: string, reason: string)
	for _, schedule in ipairs(schedules) do
		if schedule.executionId == executionId then
			schedule.cancelled = true
			schedule.cancelReason = reason
			schedule.status = Types.Status.Cancelled
			return true
		end
	end
	return false
end

function Scheduler.inspect()
	return {
		scheduleCount = #schedules,
		schedules = Serialization.deepCopy(schedules),
	}
end

function Scheduler.clear()
	table.clear(schedules)
end

return Scheduler

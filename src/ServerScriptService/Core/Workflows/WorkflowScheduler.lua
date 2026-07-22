--!strict

local Evidence = require(script.Parent.WorkflowEvidence)
local Serialization = require(script.Parent.WorkflowSerialization)

local Scheduler = {}
local queue = {}
local sequence = 0

local function compare(left: any, right: any): boolean
	if left.priority ~= right.priority then
		return left.priority > right.priority
	end
	if left.deadline ~= right.deadline then
		return left.deadline < right.deadline
	end
	return left.sequence < right.sequence
end

function Scheduler.schedule(instanceId: string, priority: number?, deadline: number?)
	sequence += 1
	local record = {
		instanceId = instanceId,
		priority = priority or 0,
		deadline = deadline or math.huge,
		sequence = sequence,
	}
	table.insert(queue, record)
	table.sort(queue, compare)
	Evidence.record("workflow scheduled", record)
	return { ok = true, code = "Ok", instanceId = instanceId }
end

function Scheduler.next()
	local record = table.remove(queue, 1)
	return if record ~= nil then Serialization.deepCopy(record) else nil
end

function Scheduler.inspect()
	return Serialization.copyArray(queue)
end

function Scheduler.clear()
	table.clear(queue)
	sequence = 0
end

return Scheduler

--!strict

local Evidence = require(script.Parent.WorkflowEvidence)
local Serialization = require(script.Parent.WorkflowSerialization)

local Compensation = {}
local records = {}

function Compensation.plan(instanceId: string, commandType: string, reason: string)
	local record = {
		instanceId = instanceId,
		commandType = commandType,
		reason = reason,
		mode = "CommandRequestOnly",
	}
	table.insert(records, record)
	Evidence.record("workflow compensation planned", record)
	return { ok = true, code = "Ok", compensation = Serialization.deepCopy(record) }
end

function Compensation.inspect()
	return Serialization.copyArray(records)
end

function Compensation.clear()
	table.clear(records)
end

return Compensation

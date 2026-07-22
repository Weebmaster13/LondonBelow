--!strict

local Serialization = require(script.Parent.WorkflowSerialization)

local Suspension = {}
local suspensions = {}

function Suspension.record(instanceId: string, waitKind: string, target: string)
	table.insert(suspensions, {
		instanceId = instanceId,
		waitKind = waitKind,
		target = target,
		suspendedAt = os.clock(),
	})
	return { ok = true, code = "Ok", instanceId = instanceId }
end

function Suspension.inspect()
	return Serialization.copyArray(suspensions)
end

function Suspension.clear()
	table.clear(suspensions)
end

return Suspension

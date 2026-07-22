--!strict

local Evidence = require(script.Parent.WorkflowEvidence)
local Serialization = require(script.Parent.WorkflowSerialization)

local Timeouts = {}
local timeouts = {}

function Timeouts.record(instanceId: string, waitState: string, timeoutTransition: string)
	local record = {
		instanceId = instanceId,
		waitState = waitState,
		timeoutTransition = timeoutTransition,
	}
	table.insert(timeouts, record)
	Evidence.record("workflow timeout recorded", record)
	return { ok = true, code = "Ok" }
end

function Timeouts.inspect()
	return Serialization.copyArray(timeouts)
end

function Timeouts.clear()
	table.clear(timeouts)
end

return Timeouts

--!strict

local Evidence = require(script.Parent.WorkflowEvidence)
local Serialization = require(script.Parent.WorkflowSerialization)
local Types = require(script.Parent.WorkflowTypes)

local Waits = {}
local waits = {}

function Waits.add(instanceId: string, waitKind: string, target: string, timeoutAt: number?)
	local valid = false
	for _, kind in pairs(Types.WaitKind) do
		if waitKind == kind then
			valid = true
			break
		end
	end
	if not valid then
		return {
			ok = false,
			code = Types.FailureType.ValidationFailure,
			message = "invalid wait kind",
		}
	end
	local record = {
		instanceId = instanceId,
		waitKind = waitKind,
		target = target,
		timeoutAt = timeoutAt,
	}
	table.insert(waits, record)
	Evidence.record("workflow wait registered", record)
	return { ok = true, code = "Ok" }
end

function Waits.inspect()
	return Serialization.copyArray(waits)
end

function Waits.clear()
	table.clear(waits)
end

return Waits

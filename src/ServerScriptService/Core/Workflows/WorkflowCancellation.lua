--!strict

local Evidence = require(script.Parent.WorkflowEvidence)
local Instances = require(script.Parent.WorkflowInstances)
local Lifecycle = require(script.Parent.WorkflowLifecycle)
local Types = require(script.Parent.WorkflowTypes)

local Cancellation = {}

function Cancellation.cancel(instanceId: string, authorized: boolean, reason: string)
	if not authorized then
		return {
			ok = false,
			code = Types.FailureType.UnauthorizedCancellation,
			message = "cancellation requires authorization",
		}
	end
	local state = Lifecycle.get(instanceId)
	if state == nil then
		return { ok = false, code = Types.FailureType.UnknownInstance, message = "unknown instance" }
	end
	local transition = Lifecycle.transition(instanceId, Types.LifecycleState.Cancelled)
	if not transition.ok then
		return transition
	end
	local result = Instances.complete(instanceId, Types.LifecycleState.Cancelled)
	Evidence.record("workflow cancelled", { instanceId = instanceId, reason = reason })
	return result
end

return Cancellation

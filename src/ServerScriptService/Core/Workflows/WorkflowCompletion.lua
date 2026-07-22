--!strict

local Instances = require(script.Parent.WorkflowInstances)
local Serialization = require(script.Parent.WorkflowSerialization)
local Types = require(script.Parent.WorkflowTypes)

local Completion = {}
local completions = {}

function Completion.validate(instanceId: string)
	local instance = Instances.get(instanceId)
	if instance == nil then
		return { ok = false, code = Types.FailureType.UnknownInstance, message = "unknown instance" }
	end
	local result = {
		instanceId = instanceId,
		workflowId = instance.workflowId,
		state = instance.state,
		validatedAt = os.clock(),
		complete = instance.completionTime ~= nil,
	}
	table.insert(completions, Serialization.deepCopy(result))
	return { ok = true, code = "Ok", completion = result }
end

function Completion.inspect()
	return Serialization.copyArray(completions)
end

function Completion.clear()
	table.clear(completions)
end

return Completion

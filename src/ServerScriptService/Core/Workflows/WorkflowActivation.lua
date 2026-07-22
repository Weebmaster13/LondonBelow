--!strict

local Serialization = require(script.Parent.WorkflowSerialization)

local Activation = {}
local activations = {}

function Activation.record(instanceId: string, correlationId: string, requester: string)
	table.insert(activations, {
		instanceId = instanceId,
		correlationId = correlationId,
		requester = requester,
		activatedAt = os.clock(),
	})
	return { ok = true, code = "Ok", instanceId = instanceId }
end

function Activation.inspect()
	return Serialization.copyArray(activations)
end

function Activation.clear()
	table.clear(activations)
end

return Activation

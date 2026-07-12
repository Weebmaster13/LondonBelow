--!strict

local Coordinator = require(script.Parent.AssetExecutionAdapterCoordinator)

local ExecutionAdapterCapabilityRuntime = {}

function ExecutionAdapterCapabilityRuntime.register(schema: any)
	return Coordinator.registerExecutionAdapterCapability(schema)
end

function ExecutionAdapterCapabilityRuntime.inspect()
	return Coordinator.inspect()
end

return ExecutionAdapterCapabilityRuntime

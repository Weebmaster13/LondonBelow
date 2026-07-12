--!strict

local Coordinator = require(script.Parent.AssetExecutionAdapterCoordinator)

local ExecutionAdapterCompatibilityRuntime = {}

function ExecutionAdapterCompatibilityRuntime.register(schema: any)
	return Coordinator.registerExecutionAdapterCompatibility(schema)
end

function ExecutionAdapterCompatibilityRuntime.inspect()
	return Coordinator.inspect()
end

return ExecutionAdapterCompatibilityRuntime

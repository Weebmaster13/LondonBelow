--!strict

local Coordinator = require(script.Parent.AssetExecutionAdapterCoordinator)

local ExecutionAdapterRuntime = {}

function ExecutionAdapterRuntime.register(schema: any)
	return Coordinator.registerExecutionAdapter(schema)
end

function ExecutionAdapterRuntime.inspect()
	return Coordinator.inspect()
end

return ExecutionAdapterRuntime

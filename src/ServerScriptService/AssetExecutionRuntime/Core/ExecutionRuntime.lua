--!strict

local Coordinator = require(script.Parent.AssetExecutionCoordinator)

local ExecutionRuntime = {}

function ExecutionRuntime.register(schema: any)
	return Coordinator.registerExecutionRuntime(schema)
end

function ExecutionRuntime.inspect()
	return Coordinator.inspect()
end

return ExecutionRuntime

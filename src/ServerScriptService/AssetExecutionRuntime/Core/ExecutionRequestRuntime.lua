--!strict

local Coordinator = require(script.Parent.AssetExecutionCoordinator)

local ExecutionRequestRuntime = {}

function ExecutionRequestRuntime.register(schema: any)
	return Coordinator.registerExecutionRequest(schema)
end

function ExecutionRequestRuntime.inspect()
	return Coordinator.inspect()
end

return ExecutionRequestRuntime

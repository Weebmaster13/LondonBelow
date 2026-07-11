--!strict

local Coordinator = require(script.Parent.AssetExecutionCoordinator)

local ExecutionBoundaryRuntime = {}

function ExecutionBoundaryRuntime.register(schema: any)
	return Coordinator.registerExecutionBoundary(schema)
end

function ExecutionBoundaryRuntime.inspect()
	return Coordinator.inspect()
end

return ExecutionBoundaryRuntime

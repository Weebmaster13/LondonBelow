--!strict

local Coordinator = require(script.Parent.AssetExecutionAdapterCoordinator)

local ExecutionAdapterBoundaryRuntime = {}

function ExecutionAdapterBoundaryRuntime.register(schema: any)
	return Coordinator.registerExecutionAdapterBoundary(schema)
end

function ExecutionAdapterBoundaryRuntime.inspect()
	return Coordinator.inspect()
end

return ExecutionAdapterBoundaryRuntime

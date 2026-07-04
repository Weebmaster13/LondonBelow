--!strict

local Coordinator = require(script.Parent.AssetExecutionDesignContractCoordinator)

local ExecutionDesignBoundaryRuntime = {}

function ExecutionDesignBoundaryRuntime.register(schema: any)
	return Coordinator.registerExecutionDesignBoundary(schema)
end

function ExecutionDesignBoundaryRuntime.inspect()
	return Coordinator.inspect()
end

return ExecutionDesignBoundaryRuntime

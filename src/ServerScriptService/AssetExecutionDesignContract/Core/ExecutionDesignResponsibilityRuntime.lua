--!strict

local Coordinator = require(script.Parent.AssetExecutionDesignContractCoordinator)

local ExecutionDesignResponsibilityRuntime = {}

function ExecutionDesignResponsibilityRuntime.register(schema: any)
	return Coordinator.registerExecutionDesignResponsibility(schema)
end

function ExecutionDesignResponsibilityRuntime.inspect()
	return Coordinator.inspect()
end

return ExecutionDesignResponsibilityRuntime

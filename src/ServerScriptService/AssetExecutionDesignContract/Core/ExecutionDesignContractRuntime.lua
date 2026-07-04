--!strict

local Coordinator = require(script.Parent.AssetExecutionDesignContractCoordinator)

local ExecutionDesignContractRuntime = {}

function ExecutionDesignContractRuntime.register(schema: any)
	return Coordinator.registerExecutionDesignContract(schema)
end

function ExecutionDesignContractRuntime.inspect()
	return Coordinator.inspect()
end

return ExecutionDesignContractRuntime

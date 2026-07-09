--!strict

local Coordinator = require(script.Parent.AssetExecutionImplementationContractCoordinator)

local ImplementationContractRuntime = {}

function ImplementationContractRuntime.register(schema: any)
	return Coordinator.registerImplementationContract(schema)
end

function ImplementationContractRuntime.inspect()
	return Coordinator.inspect()
end

return ImplementationContractRuntime

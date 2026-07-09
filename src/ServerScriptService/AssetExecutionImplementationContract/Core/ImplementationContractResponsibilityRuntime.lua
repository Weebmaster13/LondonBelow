--!strict

local Coordinator = require(script.Parent.AssetExecutionImplementationContractCoordinator)

local ImplementationContractResponsibilityRuntime = {}

function ImplementationContractResponsibilityRuntime.register(schema: any)
	return Coordinator.registerImplementationContractResponsibility(schema)
end

function ImplementationContractResponsibilityRuntime.inspect()
	return Coordinator.inspect()
end

return ImplementationContractResponsibilityRuntime

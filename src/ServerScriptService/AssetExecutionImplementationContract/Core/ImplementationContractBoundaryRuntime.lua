--!strict

local Coordinator = require(script.Parent.AssetExecutionImplementationContractCoordinator)

local ImplementationContractBoundaryRuntime = {}

function ImplementationContractBoundaryRuntime.register(schema: any)
	return Coordinator.registerImplementationContractBoundary(schema)
end

function ImplementationContractBoundaryRuntime.inspect()
	return Coordinator.inspect()
end

return ImplementationContractBoundaryRuntime

--!strict

local Coordinator = require(script.Parent.AssetExecutionImplementationReadinessCoordinator)

local ImplementationReadinessRuntime = {}

function ImplementationReadinessRuntime.register(schema: any)
	return Coordinator.registerImplementationReadiness(schema)
end

function ImplementationReadinessRuntime.inspect()
	return Coordinator.inspect()
end

return ImplementationReadinessRuntime

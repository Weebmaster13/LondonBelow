--!strict

local Coordinator = require(script.Parent.AssetExecutionImplementationReadinessCoordinator)

local ImplementationReadinessGapRuntime = {}

function ImplementationReadinessGapRuntime.register(schema: any)
	return Coordinator.registerImplementationReadinessGap(schema)
end

function ImplementationReadinessGapRuntime.inspect()
	return Coordinator.inspect()
end

return ImplementationReadinessGapRuntime

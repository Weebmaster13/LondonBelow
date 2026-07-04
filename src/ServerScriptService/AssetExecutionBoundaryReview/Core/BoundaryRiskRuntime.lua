--!strict

local Coordinator = require(script.Parent.AssetExecutionBoundaryReviewCoordinator)

local BoundaryRiskRuntime = {}

function BoundaryRiskRuntime.register(schema: any)
	return Coordinator.registerBoundaryRisk(schema)
end

function BoundaryRiskRuntime.inspect()
	return Coordinator.inspect()
end

return BoundaryRiskRuntime

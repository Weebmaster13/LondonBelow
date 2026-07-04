--!strict

local Coordinator = require(script.Parent.AssetExecutionBoundaryReviewCoordinator)

local BoundaryRequirementRuntime = {}

function BoundaryRequirementRuntime.register(schema: any)
	return Coordinator.registerBoundaryRequirement(schema)
end

function BoundaryRequirementRuntime.inspect()
	return Coordinator.inspect()
end

return BoundaryRequirementRuntime

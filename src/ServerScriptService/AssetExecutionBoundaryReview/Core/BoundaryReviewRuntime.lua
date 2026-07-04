--!strict

local Coordinator = require(script.Parent.AssetExecutionBoundaryReviewCoordinator)

local BoundaryReviewRuntime = {}

function BoundaryReviewRuntime.register(schema: any)
	return Coordinator.registerBoundaryReview(schema)
end

function BoundaryReviewRuntime.inspect()
	return Coordinator.inspect()
end

return BoundaryReviewRuntime

--!strict

local Coordinator = require(script.Parent.AssetGovernanceIntegrationCoordinator)

local GovernanceReferenceReviewRuntime = {}

function GovernanceReferenceReviewRuntime.register(schema: any)
	return Coordinator.registerGovernanceReferenceReview(schema)
end

function GovernanceReferenceReviewRuntime.inspect()
	return Coordinator.inspect()
end

return GovernanceReferenceReviewRuntime

--!strict

local Coordinator = require(script.Parent.AssetGovernanceCertificationIntegrationCoordinator)

local GovernanceCertificationIntegrationReviewRuntime = {}

function GovernanceCertificationIntegrationReviewRuntime.register(schema: any)
	return Coordinator.registerGovernanceCertificationIntegrationReview(schema)
end

function GovernanceCertificationIntegrationReviewRuntime.inspect()
	return Coordinator.inspect()
end

return GovernanceCertificationIntegrationReviewRuntime

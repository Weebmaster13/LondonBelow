--!strict

local Coordinator = require(script.Parent.AssetReadinessReviewCoordinator)

local ReadinessDecisionRuntime = {}

function ReadinessDecisionRuntime.register(schema: any)
	return Coordinator.registerReadinessDecision(schema)
end

function ReadinessDecisionRuntime.inspect()
	return Coordinator.inspect()
end

return ReadinessDecisionRuntime

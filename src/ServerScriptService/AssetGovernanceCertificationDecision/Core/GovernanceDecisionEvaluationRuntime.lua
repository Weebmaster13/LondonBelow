--!strict

local Coordinator = require(script.Parent.AssetGovernanceCertificationDecisionCoordinator)

local GovernanceDecisionEvaluationRuntime = {}

function GovernanceDecisionEvaluationRuntime.register(schema: any)
	return Coordinator.registerGovernanceDecisionEvaluation(schema)
end

function GovernanceDecisionEvaluationRuntime.inspect()
	return Coordinator.inspect()
end

return GovernanceDecisionEvaluationRuntime

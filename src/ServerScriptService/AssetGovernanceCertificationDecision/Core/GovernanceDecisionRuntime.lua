--!strict

local Coordinator = require(script.Parent.AssetGovernanceCertificationDecisionCoordinator)

local GovernanceDecisionRuntime = {}

function GovernanceDecisionRuntime.register(schema: any)
	return Coordinator.registerGovernanceDecision(schema)
end

function GovernanceDecisionRuntime.inspect()
	return Coordinator.inspect()
end

return GovernanceDecisionRuntime

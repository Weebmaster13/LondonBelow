--!strict

local Coordinator = require(script.Parent.AssetGovernanceCertificationDecisionCoordinator)

local GovernanceDecisionRequirementRuntime = {}

function GovernanceDecisionRequirementRuntime.register(schema: any)
	return Coordinator.registerGovernanceDecisionRequirement(schema)
end

function GovernanceDecisionRequirementRuntime.inspect()
	return Coordinator.inspect()
end

return GovernanceDecisionRequirementRuntime

--!strict

local Coordinator = require(script.Parent.AssetGovernanceCertificationDecisionCoordinator)

local GovernanceDecisionAuditRuntime = {}

function GovernanceDecisionAuditRuntime.register(schema: any)
	return Coordinator.registerGovernanceDecisionAudit(schema)
end

function GovernanceDecisionAuditRuntime.inspect()
	return Coordinator.inspect()
end

return GovernanceDecisionAuditRuntime

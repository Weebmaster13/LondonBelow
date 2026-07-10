--!strict

local Coordinator = require(script.Parent.AssetGovernanceIntegrationCoordinator)

local GovernanceIntegrationAuditRuntime = {}

function GovernanceIntegrationAuditRuntime.register(schema: any)
	return Coordinator.registerGovernanceIntegrationAudit(schema)
end

function GovernanceIntegrationAuditRuntime.inspect()
	return Coordinator.inspect()
end

return GovernanceIntegrationAuditRuntime

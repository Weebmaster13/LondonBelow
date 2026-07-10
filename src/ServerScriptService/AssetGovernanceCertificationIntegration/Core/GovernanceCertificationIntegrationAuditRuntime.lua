--!strict

local Coordinator = require(script.Parent.AssetGovernanceCertificationIntegrationCoordinator)

local GovernanceCertificationIntegrationAuditRuntime = {}

function GovernanceCertificationIntegrationAuditRuntime.register(schema: any)
	return Coordinator.registerGovernanceCertificationIntegrationAudit(schema)
end

function GovernanceCertificationIntegrationAuditRuntime.inspect()
	return Coordinator.inspect()
end

return GovernanceCertificationIntegrationAuditRuntime

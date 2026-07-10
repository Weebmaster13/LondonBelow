--!strict

local Coordinator = require(script.Parent.AssetGovernanceCertificationCoordinator)

local GovernanceCertificationAuditRuntime = {}

function GovernanceCertificationAuditRuntime.register(schema: any)
	return Coordinator.registerGovernanceCertificationAudit(schema)
end

function GovernanceCertificationAuditRuntime.inspect()
	return Coordinator.inspect()
end

return GovernanceCertificationAuditRuntime

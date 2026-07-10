--!strict

local Coordinator = require(script.Parent.AssetGovernanceCertificationInspectionCoordinator)

local GovernanceInspectionAuditRuntime = {}

function GovernanceInspectionAuditRuntime.register(schema: any)
	return Coordinator.registerGovernanceInspectionAudit(schema)
end

function GovernanceInspectionAuditRuntime.inspect()
	return Coordinator.inspect()
end

return GovernanceInspectionAuditRuntime

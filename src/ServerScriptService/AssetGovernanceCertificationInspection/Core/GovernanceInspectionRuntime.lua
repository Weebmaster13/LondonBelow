--!strict

local Coordinator = require(script.Parent.AssetGovernanceCertificationInspectionCoordinator)

local GovernanceInspectionRuntime = {}

function GovernanceInspectionRuntime.register(schema: any)
	return Coordinator.registerGovernanceInspection(schema)
end

function GovernanceInspectionRuntime.inspect()
	return Coordinator.inspect()
end

return GovernanceInspectionRuntime

--!strict

local Coordinator = require(script.Parent.AssetGovernanceCertificationInspectionCoordinator)

local GovernanceInspectionFindingRuntime = {}

function GovernanceInspectionFindingRuntime.register(schema: any)
	return Coordinator.registerGovernanceInspectionFinding(schema)
end

function GovernanceInspectionFindingRuntime.inspect()
	return Coordinator.inspect()
end

return GovernanceInspectionFindingRuntime

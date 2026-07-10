--!strict

local Coordinator = require(script.Parent.AssetGovernanceCertificationInspectionCoordinator)

local GovernanceInspectionObservationRuntime = {}

function GovernanceInspectionObservationRuntime.register(schema: any)
	return Coordinator.registerGovernanceInspectionObservation(schema)
end

function GovernanceInspectionObservationRuntime.inspect()
	return Coordinator.inspect()
end

return GovernanceInspectionObservationRuntime

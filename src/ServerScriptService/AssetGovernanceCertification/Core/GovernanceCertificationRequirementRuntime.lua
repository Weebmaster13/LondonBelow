--!strict

local Coordinator = require(script.Parent.AssetGovernanceCertificationCoordinator)

local GovernanceCertificationRequirementRuntime = {}

function GovernanceCertificationRequirementRuntime.register(schema: any)
	return Coordinator.registerGovernanceCertificationRequirement(schema)
end

function GovernanceCertificationRequirementRuntime.inspect()
	return Coordinator.inspect()
end

return GovernanceCertificationRequirementRuntime

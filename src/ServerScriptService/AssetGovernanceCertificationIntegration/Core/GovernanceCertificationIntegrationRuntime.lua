--!strict

local Coordinator = require(script.Parent.AssetGovernanceCertificationIntegrationCoordinator)

local GovernanceCertificationIntegrationRuntime = {}

function GovernanceCertificationIntegrationRuntime.register(schema: any)
	return Coordinator.registerGovernanceCertificationIntegration(schema)
end

function GovernanceCertificationIntegrationRuntime.inspect()
	return Coordinator.inspect()
end

return GovernanceCertificationIntegrationRuntime

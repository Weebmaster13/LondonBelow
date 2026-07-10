--!strict

local Coordinator = require(script.Parent.AssetGovernanceCertificationIntegrationCoordinator)

local GovernanceCertificationIntegrationChainRuntime = {}

function GovernanceCertificationIntegrationChainRuntime.register(schema: any)
	return Coordinator.registerGovernanceCertificationIntegrationChain(schema)
end

function GovernanceCertificationIntegrationChainRuntime.inspect()
	return Coordinator.inspect()
end

return GovernanceCertificationIntegrationChainRuntime

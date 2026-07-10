--!strict

local Coordinator = require(script.Parent.AssetGovernanceIntegrationCoordinator)

local GovernanceChainRuntime = {}

function GovernanceChainRuntime.register(schema: any)
	return Coordinator.registerGovernanceChain(schema)
end

function GovernanceChainRuntime.inspect()
	return Coordinator.inspect()
end

return GovernanceChainRuntime

--!strict

local Coordinator = require(script.Parent.AssetGovernanceIntegrationCoordinator)

local GovernanceRuntimeNodeRuntime = {}

function GovernanceRuntimeNodeRuntime.register(schema: any)
	return Coordinator.registerGovernanceRuntimeNode(schema)
end

function GovernanceRuntimeNodeRuntime.inspect()
	return Coordinator.inspect()
end

return GovernanceRuntimeNodeRuntime

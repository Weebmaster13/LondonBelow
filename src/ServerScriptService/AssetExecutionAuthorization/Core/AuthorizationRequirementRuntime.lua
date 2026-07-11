--!strict

local Coordinator = require(script.Parent.AssetExecutionAuthorizationCoordinator)

local AuthorizationRequirementRuntime = {}

function AuthorizationRequirementRuntime.register(schema: any)
	return Coordinator.registerExecutionAuthorizationRequirement(schema)
end

function AuthorizationRequirementRuntime.inspect()
	return Coordinator.inspect()
end

return AuthorizationRequirementRuntime

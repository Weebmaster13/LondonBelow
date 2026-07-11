--!strict

local Coordinator = require(script.Parent.AssetExecutionAuthorizationCoordinator)

local AuthorizationRuntime = {}

function AuthorizationRuntime.register(schema: any)
	return Coordinator.registerExecutionAuthorization(schema)
end

function AuthorizationRuntime.inspect()
	return Coordinator.inspect()
end

return AuthorizationRuntime

--!strict

local Coordinator = require(script.Parent.AssetExecutionAuthorizationCoordinator)

local AuthorizationBoundaryRuntime = {}

function AuthorizationBoundaryRuntime.register(schema: any)
	return Coordinator.registerExecutionAuthorizationBoundary(schema)
end

function AuthorizationBoundaryRuntime.inspect()
	return Coordinator.inspect()
end

return AuthorizationBoundaryRuntime

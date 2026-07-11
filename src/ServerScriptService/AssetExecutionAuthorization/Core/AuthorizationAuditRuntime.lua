--!strict

local Coordinator = require(script.Parent.AssetExecutionAuthorizationCoordinator)

local AuthorizationAuditRuntime = {}

function AuthorizationAuditRuntime.register(schema: any)
	return Coordinator.registerExecutionAuthorizationAudit(schema)
end

function AuthorizationAuditRuntime.inspect()
	return Coordinator.inspect()
end

return AuthorizationAuditRuntime

--!strict

local Coordinator = require(script.Parent.AssetExecutionPermitCoordinator)

local ExecutionPermitAuditRuntime = {}

function ExecutionPermitAuditRuntime.register(schema: any)
	return Coordinator.registerExecutionPermitAudit(schema)
end

function ExecutionPermitAuditRuntime.inspect()
	return Coordinator.inspect()
end

return ExecutionPermitAuditRuntime

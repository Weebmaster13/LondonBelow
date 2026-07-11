--!strict

local Coordinator = require(script.Parent.AssetExecutionCoordinator)

local ExecutionAuditRuntime = {}

function ExecutionAuditRuntime.register(schema: any)
	return Coordinator.registerExecutionAudit(schema)
end

function ExecutionAuditRuntime.inspect()
	return Coordinator.inspect()
end

return ExecutionAuditRuntime

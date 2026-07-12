--!strict

local Coordinator = require(script.Parent.AssetExecutionAdapterCoordinator)

local ExecutionAdapterAuditRuntime = {}

function ExecutionAdapterAuditRuntime.register(schema: any)
	return Coordinator.registerExecutionAdapterAudit(schema)
end

function ExecutionAdapterAuditRuntime.inspect()
	return Coordinator.inspect()
end

return ExecutionAdapterAuditRuntime

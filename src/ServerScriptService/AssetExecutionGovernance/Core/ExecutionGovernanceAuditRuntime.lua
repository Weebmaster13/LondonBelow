--!strict

local Coordinator = require(script.Parent.AssetExecutionGovernanceCoordinator)

local ExecutionGovernanceAuditRuntime = {}

function ExecutionGovernanceAuditRuntime.register(schema: any)
	return Coordinator.registerExecutionGovernanceAudit(schema)
end

function ExecutionGovernanceAuditRuntime.inspect()
	return Coordinator.inspect()
end

return ExecutionGovernanceAuditRuntime

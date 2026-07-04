--!strict

local Coordinator = require(script.Parent.AssetExecutionDesignContractCoordinator)

local ExecutionDesignAuditRuntime = {}

function ExecutionDesignAuditRuntime.register(schema: any)
	return Coordinator.registerExecutionDesignAudit(schema)
end

function ExecutionDesignAuditRuntime.inspect()
	return Coordinator.inspect()
end

return ExecutionDesignAuditRuntime

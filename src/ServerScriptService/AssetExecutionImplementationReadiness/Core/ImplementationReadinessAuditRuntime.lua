--!strict

local Coordinator = require(script.Parent.AssetExecutionImplementationReadinessCoordinator)

local ImplementationReadinessAuditRuntime = {}

function ImplementationReadinessAuditRuntime.register(schema: any)
	return Coordinator.registerImplementationReadinessAudit(schema)
end

function ImplementationReadinessAuditRuntime.inspect()
	return Coordinator.inspect()
end

return ImplementationReadinessAuditRuntime

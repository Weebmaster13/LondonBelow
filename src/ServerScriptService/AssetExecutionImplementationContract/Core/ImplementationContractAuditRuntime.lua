--!strict

local Coordinator = require(script.Parent.AssetExecutionImplementationContractCoordinator)

local ImplementationContractAuditRuntime = {}

function ImplementationContractAuditRuntime.register(schema: any)
	return Coordinator.registerImplementationContractAudit(schema)
end

function ImplementationContractAuditRuntime.inspect()
	return Coordinator.inspect()
end

return ImplementationContractAuditRuntime

--!strict

local Coordinator = require(script.Parent.AssetApprovalLedgerCoordinator)

local ApprovalAuditRuntime = {}

function ApprovalAuditRuntime.register(schema: any)
	return Coordinator.registerApprovalAudit(schema)
end

function ApprovalAuditRuntime.inspect()
	return Coordinator.inspect()
end

return ApprovalAuditRuntime

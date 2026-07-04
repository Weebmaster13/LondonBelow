--!strict

local Coordinator = require(script.Parent.AssetApprovalLedgerCoordinator)

local ApprovalRevocationRuntime = {}

function ApprovalRevocationRuntime.register(schema: any)
	return Coordinator.registerApprovalRevocation(schema)
end

function ApprovalRevocationRuntime.inspect()
	return Coordinator.inspect()
end

return ApprovalRevocationRuntime

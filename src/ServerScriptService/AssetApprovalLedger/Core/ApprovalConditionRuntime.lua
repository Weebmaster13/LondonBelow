--!strict

local Coordinator = require(script.Parent.AssetApprovalLedgerCoordinator)

local ApprovalConditionRuntime = {}

function ApprovalConditionRuntime.register(schema: any)
	return Coordinator.registerApprovalCondition(schema)
end

function ApprovalConditionRuntime.inspect()
	return Coordinator.inspect()
end

return ApprovalConditionRuntime

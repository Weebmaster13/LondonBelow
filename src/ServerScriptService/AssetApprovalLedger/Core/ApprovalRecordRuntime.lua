--!strict

local Coordinator = require(script.Parent.AssetApprovalLedgerCoordinator)

local ApprovalRecordRuntime = {}

function ApprovalRecordRuntime.register(schema: any)
	return Coordinator.registerApprovalRecord(schema)
end

function ApprovalRecordRuntime.inspect()
	return Coordinator.inspect()
end

return ApprovalRecordRuntime

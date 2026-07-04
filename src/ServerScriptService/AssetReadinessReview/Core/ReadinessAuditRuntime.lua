--!strict

local Coordinator = require(script.Parent.AssetReadinessReviewCoordinator)

local ReadinessAuditRuntime = {}

function ReadinessAuditRuntime.register(schema: any)
	return Coordinator.registerReadinessAudit(schema)
end

function ReadinessAuditRuntime.inspect()
	return Coordinator.inspect()
end

return ReadinessAuditRuntime

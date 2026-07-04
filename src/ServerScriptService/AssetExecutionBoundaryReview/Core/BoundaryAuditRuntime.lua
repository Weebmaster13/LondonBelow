--!strict

local Coordinator = require(script.Parent.AssetExecutionBoundaryReviewCoordinator)

local BoundaryAuditRuntime = {}

function BoundaryAuditRuntime.register(schema: any)
	return Coordinator.registerBoundaryAudit(schema)
end

function BoundaryAuditRuntime.inspect()
	return Coordinator.inspect()
end

return BoundaryAuditRuntime

--!strict

local Coordinator = require(script.Parent.AssetRuntimeGateCoordinator)

local RuntimeGateAuditRuntime = {}

function RuntimeGateAuditRuntime.register(schema: any)
	return Coordinator.registerRuntimeGateAudit(schema)
end

function RuntimeGateAuditRuntime.inspect()
	return Coordinator.inspect()
end

return RuntimeGateAuditRuntime

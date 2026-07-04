--!strict

local Coordinator = require(script.Parent.AssetExecutionPermitCoordinator)

local ExecutionPermitRestrictionRuntime = {}

function ExecutionPermitRestrictionRuntime.register(schema: any)
	return Coordinator.registerExecutionPermitRestriction(schema)
end

function ExecutionPermitRestrictionRuntime.inspect()
	return Coordinator.inspect()
end

return ExecutionPermitRestrictionRuntime

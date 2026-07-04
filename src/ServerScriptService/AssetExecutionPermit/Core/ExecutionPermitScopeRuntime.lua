--!strict

local Coordinator = require(script.Parent.AssetExecutionPermitCoordinator)

local ExecutionPermitScopeRuntime = {}

function ExecutionPermitScopeRuntime.register(schema: any)
	return Coordinator.registerExecutionPermitScope(schema)
end

function ExecutionPermitScopeRuntime.inspect()
	return Coordinator.inspect()
end

return ExecutionPermitScopeRuntime

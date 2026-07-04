--!strict

local Coordinator = require(script.Parent.AssetExecutionPermitCoordinator)

local ExecutionPermitRuntime = {}

function ExecutionPermitRuntime.register(schema: any)
	return Coordinator.registerExecutionPermit(schema)
end

function ExecutionPermitRuntime.inspect()
	return Coordinator.inspect()
end

return ExecutionPermitRuntime

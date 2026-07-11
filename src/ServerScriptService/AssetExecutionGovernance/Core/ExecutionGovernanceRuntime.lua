--!strict

local Coordinator = require(script.Parent.AssetExecutionGovernanceCoordinator)

local ExecutionGovernanceRuntime = {}

function ExecutionGovernanceRuntime.register(schema: any)
	return Coordinator.registerExecutionGovernance(schema)
end

function ExecutionGovernanceRuntime.inspect()
	return Coordinator.inspect()
end

return ExecutionGovernanceRuntime

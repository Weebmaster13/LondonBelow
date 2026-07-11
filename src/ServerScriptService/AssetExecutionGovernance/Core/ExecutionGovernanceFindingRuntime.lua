--!strict

local Coordinator = require(script.Parent.AssetExecutionGovernanceCoordinator)

local ExecutionGovernanceFindingRuntime = {}

function ExecutionGovernanceFindingRuntime.register(schema: any)
	return Coordinator.registerExecutionGovernanceFinding(schema)
end

function ExecutionGovernanceFindingRuntime.inspect()
	return Coordinator.inspect()
end

return ExecutionGovernanceFindingRuntime

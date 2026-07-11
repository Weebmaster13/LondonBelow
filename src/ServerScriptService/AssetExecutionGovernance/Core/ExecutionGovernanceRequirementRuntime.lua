--!strict

local Coordinator = require(script.Parent.AssetExecutionGovernanceCoordinator)

local ExecutionGovernanceRequirementRuntime = {}

function ExecutionGovernanceRequirementRuntime.register(schema: any)
	return Coordinator.registerExecutionGovernanceRequirement(schema)
end

function ExecutionGovernanceRequirementRuntime.inspect()
	return Coordinator.inspect()
end

return ExecutionGovernanceRequirementRuntime

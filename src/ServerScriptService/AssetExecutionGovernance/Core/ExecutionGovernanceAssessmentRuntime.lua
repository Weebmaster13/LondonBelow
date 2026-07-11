--!strict

local Coordinator = require(script.Parent.AssetExecutionGovernanceCoordinator)

local ExecutionGovernanceAssessmentRuntime = {}

function ExecutionGovernanceAssessmentRuntime.register(schema: any)
	return Coordinator.registerExecutionGovernanceAssessment(schema)
end

function ExecutionGovernanceAssessmentRuntime.inspect()
	return Coordinator.inspect()
end

return ExecutionGovernanceAssessmentRuntime

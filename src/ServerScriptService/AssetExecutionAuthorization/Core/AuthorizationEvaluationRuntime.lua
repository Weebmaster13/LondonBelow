--!strict

local Coordinator = require(script.Parent.AssetExecutionAuthorizationCoordinator)

local AuthorizationEvaluationRuntime = {}

function AuthorizationEvaluationRuntime.register(schema: any)
	return Coordinator.registerExecutionAuthorizationEvaluation(schema)
end

function AuthorizationEvaluationRuntime.inspect()
	return Coordinator.inspect()
end

return AuthorizationEvaluationRuntime

--!strict

local Coordinator = require(script.Parent.AssetReadinessReviewCoordinator)

local ReadinessGateRuntime = {}

function ReadinessGateRuntime.register(schema: any)
	return Coordinator.registerReadinessGate(schema)
end

function ReadinessGateRuntime.inspect()
	return Coordinator.inspect()
end

return ReadinessGateRuntime

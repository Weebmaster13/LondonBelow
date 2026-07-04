--!strict

local Coordinator = require(script.Parent.AssetReadinessReviewCoordinator)

local ReadinessChecklistRuntime = {}

function ReadinessChecklistRuntime.register(schema: any)
	return Coordinator.registerReadinessChecklist(schema)
end

function ReadinessChecklistRuntime.inspect()
	return Coordinator.inspect()
end

return ReadinessChecklistRuntime

--!strict

local Coordinator = require(script.Parent.AssetReadinessReviewCoordinator)

local ReadinessFindingRuntime = {}

function ReadinessFindingRuntime.register(schema: any)
	return Coordinator.registerReadinessFinding(schema)
end

function ReadinessFindingRuntime.inspect()
	return Coordinator.inspect()
end

return ReadinessFindingRuntime

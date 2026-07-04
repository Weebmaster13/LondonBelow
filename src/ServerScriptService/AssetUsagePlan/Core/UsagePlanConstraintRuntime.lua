--!strict

local Coordinator = require(script.Parent.AssetUsagePlanCoordinator)

return {
	register = Coordinator.registerUsagePlanConstraint,
}

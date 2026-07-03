--!strict

local Coordinator = require(script.Parent.ConditionCoordinator)

return {
	register = Coordinator.registerConditionDependency,
}

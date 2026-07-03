--!strict
local Coordinator = require(script.Parent.RuntimeSchedulerCoordinator)
return { register = Coordinator.registerScheduleBudget }

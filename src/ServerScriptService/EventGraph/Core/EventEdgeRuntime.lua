--!strict
local Coordinator = require(script.Parent.EventGraphCoordinator)
return { register = Coordinator.registerEventEdge }

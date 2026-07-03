--!strict

local Coordinator = require(script.Parent.StateMachineCoordinator)

return {
	register = Coordinator.registerStateMachineOutcome,
}

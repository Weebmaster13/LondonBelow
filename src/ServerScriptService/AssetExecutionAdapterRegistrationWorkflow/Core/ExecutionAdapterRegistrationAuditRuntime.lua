--!strict

local Coordinator = require(script.Parent.AssetExecutionAdapterRegistrationWorkflowCoordinator)

return {
	register = Coordinator.registerExecutionAdapterRegistrationAudit,
}

--!strict

local Coordinator = require(script.Parent.AssetExecutionAdapterRegistryCoordinator)

return {
	register = Coordinator.registerExecutionAdapterRegistryCompatibility,
}

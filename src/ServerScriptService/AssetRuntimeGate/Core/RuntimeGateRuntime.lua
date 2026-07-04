--!strict

local Coordinator = require(script.Parent.AssetRuntimeGateCoordinator)

local RuntimeGateRuntime = {}

function RuntimeGateRuntime.register(schema: any)
	return Coordinator.registerRuntimeGate(schema)
end

function RuntimeGateRuntime.inspect()
	return Coordinator.inspect()
end

return RuntimeGateRuntime

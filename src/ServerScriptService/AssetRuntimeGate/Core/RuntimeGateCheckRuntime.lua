--!strict

local Coordinator = require(script.Parent.AssetRuntimeGateCoordinator)

local RuntimeGateCheckRuntime = {}

function RuntimeGateCheckRuntime.register(schema: any)
	return Coordinator.registerRuntimeGateCheck(schema)
end

function RuntimeGateCheckRuntime.inspect()
	return Coordinator.inspect()
end

return RuntimeGateCheckRuntime

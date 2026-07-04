--!strict

local Coordinator = require(script.Parent.AssetRuntimeGateCoordinator)

local RuntimeGateBlockRuntime = {}

function RuntimeGateBlockRuntime.register(schema: any)
	return Coordinator.registerRuntimeGateBlock(schema)
end

function RuntimeGateBlockRuntime.inspect()
	return Coordinator.inspect()
end

return RuntimeGateBlockRuntime

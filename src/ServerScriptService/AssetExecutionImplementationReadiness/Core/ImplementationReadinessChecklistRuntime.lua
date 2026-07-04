--!strict

local Coordinator = require(script.Parent.AssetExecutionImplementationReadinessCoordinator)

local ImplementationReadinessChecklistRuntime = {}

function ImplementationReadinessChecklistRuntime.register(schema: any)
	return Coordinator.registerImplementationReadinessChecklist(schema)
end

function ImplementationReadinessChecklistRuntime.inspect()
	return Coordinator.inspect()
end

return ImplementationReadinessChecklistRuntime

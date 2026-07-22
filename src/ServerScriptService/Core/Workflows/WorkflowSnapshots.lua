--!strict

local Diagnostics = require(script.Parent.WorkflowDiagnostics)
local Serialization = require(script.Parent.WorkflowSerialization)
local Types = require(script.Parent.WorkflowTypes)

local Snapshots = {}

function Snapshots.capture(runtime: any)
	return Serialization.deepCopy({
		providerName = Types.ProviderName,
		workflowOrchestrationSnapshot = {
			workflowOrchestrationPosture = if runtime.isShutdown() then "Shutdown" else "Healthy",
			definitions = runtime.getDefinitions(),
			instances = runtime.getInstances(),
			counters = runtime.getCounters(),
		},
		diagnosticsSnapshot = Diagnostics.capture(runtime),
	})
end

return Snapshots

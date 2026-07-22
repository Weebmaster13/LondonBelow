--!strict

local Serialization = require(script.Parent.WorkflowSerialization)

local Inspection = {}

function Inspection.capture(runtime: any)
	return Serialization.deepCopy({
		definitions = runtime.getDefinitions(),
		instances = runtime.getInstances(),
		counters = runtime.getCounters(),
	})
end

return Inspection

--!strict

local Serialization = require(script.Parent.CommandSerialization)

local Inspection = {}

function Inspection.capture(views: any)
	return Serialization.deepCopy({
		runtime = views.runtime,
		commandQueue = views.commandQueue,
		execution = views.execution,
		transactions = views.transactions,
		locks = views.locks,
		retries = views.retries,
		replay = views.replay,
		recovery = views.recovery,
		evidence = views.evidence,
		diagnostics = views.diagnostics,
		timelines = views.timelines,
		correlations = views.correlations,
		traceGraph = views.traceGraph,
	})
end

return Inspection

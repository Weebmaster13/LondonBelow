--!strict

local Types = require(script.Parent.CommandTypes)

local Diagnostics = {}

function Diagnostics.capture(runtime: any)
	local counters = runtime.getCounters()
	return {
		commandBusPosture = if runtime.isShutdown() then "Shutdown" else "Healthy",
		registeredCommandTypes = counters.commandTypes,
		registeredRequesters = counters.requesters,
		registeredHandlers = counters.handlers,
		queuedCommands = counters.queued,
		routingCommands = counters.routing,
		executingCommands = counters.executing,
		succeededCommands = counters.succeeded,
		cancelledCommands = counters.cancelled,
		rejectedCommands = counters.rejected,
		failedCommands = counters.failed,
		queueOverflows = counters.queueOverflows,
		idempotencyRejects = counters.idempotencyRejects,
		maximumQueueDepth = counters.maximumQueueDepth,
		lastCommandId = counters.lastCommandId,
		lastFailure = counters.lastFailure,
		limits = Types.Limits,
	}
end

return Diagnostics

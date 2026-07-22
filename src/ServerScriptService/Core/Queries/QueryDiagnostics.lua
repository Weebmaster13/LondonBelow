--!strict

local Types = require(script.Parent.QueryTypes)

local Diagnostics = {}

function Diagnostics.capture(runtime: any)
	local counters = runtime.getCounters()
	return {
		queryBusPosture = if runtime.isShutdown() then "Shutdown" else "Healthy",
		registeredQueryTypes = counters.queryTypes,
		registeredRequesters = counters.requesters,
		registeredHandlers = counters.handlers,
		queuedQueries = counters.queued,
		dispatchedQueries = counters.dispatched,
		executingQueries = counters.executing,
		completedQueries = counters.completed,
		cancelledQueries = counters.cancelled,
		rejectedQueries = counters.rejected,
		failedQueries = counters.failed,
		authorizationFailures = counters.authorizationFailures,
		cacheBehavior = counters.cacheBehavior,
		projectionCount = counters.projectionCount,
		readModelCount = counters.readModelCount,
		queryMetrics = counters.metrics,
		queryHealth = counters.health,
		queryProfiler = counters.profiler,
		resourceBudgets = counters.budgets.resourceBudgets,
		performanceBudgets = counters.budgets.performanceBudgets,
		lastQueryId = counters.lastQueryId,
		lastFailure = counters.lastFailure,
		limits = Types.Limits,
	}
end

return Diagnostics

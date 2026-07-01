--!strict
-- Diagnostics aggregation for Horror Orchestration.

local Diagnostics = {}

function Diagnostics.capture(state: any, dependencies: { [string]: any })
	local runtime = dependencies.State.inspect()
	local queue = dependencies.Queue.inspect()
	return {
		initialized = state.initialized,
		started = state.started,
		mode = state.mode,
		pressureBudget = runtime.pressureBudget,
		queueSize = queue.size,
		pendingRequests = queue.pending,
		recentDecisions = runtime.recentDecisions,
		suppressedDecisions = runtime.suppressedDecisions,
		delayedDecisionCount = runtime.counters.delayed,
		releaseDecisionCount = runtime.counters.releases,
		coordinationBundles = runtime.coordinationBundles,
		validationFailures = runtime.counters.validationFailures,
		counters = runtime.counters,
		selfChecks = state.lastSelfChecks,
		health = {
			healthy = state.initialized and state.mode == "ApprovalOnly",
			status = if not state.initialized
				then "NotInitialized"
				elseif state.started then "Running"
				else "Ready",
			message = "Horror Orchestration is approval-only and performs no horror execution.",
		},
	}
end

function Diagnostics.validate(dependencies: { [string]: any }): (boolean, string?)
	return dependencies.Validator.validate()
end

return Diagnostics

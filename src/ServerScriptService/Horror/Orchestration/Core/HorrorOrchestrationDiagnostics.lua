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
		bundleCount = #runtime.coordinationBundles,
		suppressionReasons = (function()
			local reasons = {}
			for _, bundle in ipairs(runtime.suppressedDecisions) do
				for _, reason in ipairs(bundle.reasons or {}) do
					table.insert(reasons, reason)
				end
			end
			return reasons
		end)(),
		releaseReasons = (function()
			local reasons = {}
			for _, bundle in ipairs(runtime.recentDecisions) do
				if bundle.releasePlanned then
					for _, reason in ipairs(bundle.reasons or {}) do
						table.insert(reasons, reason)
					end
				end
			end
			return reasons
		end)(),
		scareEligibilityResults = (function()
			local results = {}
			for _, bundle in ipairs(runtime.recentDecisions) do
				if bundle.metadata ~= nil and bundle.metadata.scareEligible ~= nil then
					table.insert(results, {
						requestId = bundle.requestId,
						scareEligible = bundle.metadata.scareEligible,
						action = bundle.action,
						reasons = bundle.reasons,
					})
				end
			end
			return results
		end)(),
		validationFailures = runtime.counters.validationFailures,
		counters = runtime.counters,
		seenRequestCount = runtime.seenRequestCount,
		seenRequestLimit = runtime.seenRequestLimit,
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

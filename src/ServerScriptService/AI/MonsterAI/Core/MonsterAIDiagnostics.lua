--!strict
-- Diagnostics aggregation for Monster AI execution foundation.

local Diagnostics = {}

function Diagnostics.capture(runtime: any, dependencies: { [string]: any })
	local registry = dependencies.Registry.inspect()
	local state = dependencies.State.inspect()
	return {
		initialized = runtime.initialized,
		started = runtime.started,
		mode = runtime.mode,
		monsterCount = registry.monsterCount,
		intentCount = #state.intentRecords,
		executionRecordCount = #state.executionRecords,
		validationFailureCount = #state.validationFailures,
		seenIntentCount = state.seenIntentCount,
		dryRunCount = state.counters.dryRunApplied,
		observationEmissionCount = state.counters.observationsEmitted,
		recentIntents = state.intentRecords,
		recentExecutions = state.executionRecords,
		validationFailures = state.validationFailures,
		limits = state.limits,
		registry = registry,
		state = state,
		lastSelfChecks = runtime.lastSelfChecks,
		health = {
			healthy = runtime.initialized and runtime.mode == "DryRunOnly",
			status = if not runtime.initialized
				then "NotInitialized"
				elseif runtime.started then "Running"
				else "Ready",
			message = "Monster AI execution foundation is dry-run only and subordinate to approved intent.",
		},
	}
end

function Diagnostics.validate(dependencies: { [string]: any }): (boolean, string?)
	local registry = dependencies.Registry.inspect()
	if registry.monsterCount > registry.monsterLimit then
		return false, "Monster AI registry exceeded limit"
	end
	return dependencies.Validator.validate()
end

return Diagnostics

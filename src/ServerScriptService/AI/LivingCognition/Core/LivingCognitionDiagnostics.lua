--!strict
-- Diagnostics aggregation for Living Cognition.

local Diagnostics = {}

function Diagnostics.capture(runtime: any, dependencies: { [string]: any })
	local registry = dependencies.Registry.inspect()
	local state = dependencies.State.inspect()
	return {
		initialized = runtime.initialized,
		started = runtime.started,
		mode = runtime.mode,
		entityCount = registry.entityCount,
		counts = state.counts,
		traces = state.traces,
		traceCount = #state.traces,
		confidenceHistory = state.confidenceHistory,
		lifecycleTransitions = state.lifecycleTransitions,
		validationFailures = state.validationFailures,
		validationFailureCount = #state.validationFailures,
		diagnosticsHistory = state.diagnosticsHistory,
		limits = state.limits,
		lastSelfChecks = runtime.lastSelfChecks,
		serializationStatus = {
			healthy = true,
			message = "Diagnostics are deep-copied and serialization rejects unsafe values.",
		},
		snapshotIsolation = if runtime.lastSelfChecks ~= nil
			then runtime.lastSelfChecks.snapshotIsolation == true
			else nil,
		health = {
			healthy = runtime.initialized and runtime.mode == "CognitionOnly",
			status = if not runtime.initialized
				then "NotInitialized"
				elseif runtime.started then "Running"
				else "Ready",
			message = "Living Cognition is cognition-only and execution-free.",
		},
	}
end

function Diagnostics.validate(dependencies: { [string]: any }): (boolean, string?)
	return dependencies.Validation.validate()
end

return Diagnostics

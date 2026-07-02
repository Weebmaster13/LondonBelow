--!strict
-- Diagnostics aggregation for Narrative Runtime foundation.

local Diagnostics = {}

function Diagnostics.capture(runtime: any, dependencies: { [string]: any })
	local state = dependencies.State.inspect()
	return {
		initialized = runtime.initialized,
		started = runtime.started,
		mode = runtime.mode,
		beatCount = state.beatCount,
		gateCount = state.gateCount,
		revealEligibilityCount = state.revealEligibilityCount,
		emotionalProtectionCount = state.emotionalProtectionCount,
		validationFailureCount = #state.validationFailures,
		state = state,
		lastSelfChecks = runtime.lastSelfChecks,
		health = {
			healthy = runtime.initialized
				and runtime.mode == "ServerAuthoritativeNarrativeFoundation",
			status = if not runtime.initialized
				then "NotInitialized"
				elseif runtime.started then "Running"
				else "Ready",
			message = "Narrative Runtime is server-authoritative schema and eligibility state only.",
		},
	}
end

function Diagnostics.validate(dependencies: { [string]: any }): (boolean, string?)
	return dependencies.Validation.validate()
end

return Diagnostics

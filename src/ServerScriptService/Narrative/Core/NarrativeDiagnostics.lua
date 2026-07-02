--!strict
-- Diagnostics aggregation for Narrative Runtime foundation.

local Diagnostics = {}

local function proveSnapshotIsolation(state: any): boolean
	local snapshot = state.inspect()
	snapshot.beatCount = 999999
	return state.inspect().beatCount ~= 999999
end

function Diagnostics.capture(runtime: any, dependencies: { [string]: any })
	local state = dependencies.State.inspect()
	local validationOk, validationReason = dependencies.Validation.validate()
	return {
		initialized = runtime.initialized,
		started = runtime.started,
		mode = runtime.mode,
		beatCount = state.beatCount,
		gateCount = state.gateCount,
		revealEligibilityCount = state.revealEligibilityCount,
		emotionalProtectionCount = state.emotionalProtectionCount,
		validationFailureCount = #state.validationFailures,
		recentSanitizedValidationFailures = state.recentValidationFailures,
		snapshotCount = state.snapshotCount,
		runtimeLimits = state.limits,
		serializationStatus = {
			safeExportOnly = true,
			rejectsInstances = true,
			rejectsCycles = true,
			rejectsUnsafeRuntimeValues = true,
			rejectsOversizedStrings = true,
			rejectsOversizedNodeCounts = true,
			rejectsOverlyDeepPayloads = true,
		},
		snapshotIsolationProof = proveSnapshotIsolation(dependencies.State),
		state = state,
		lastSelfChecks = runtime.lastSelfChecks,
		health = {
			healthy = runtime.initialized
				and runtime.mode == "ServerAuthoritativeNarrativeFoundation"
				and validationOk,
			status = if not runtime.initialized
				then "NotInitialized"
				elseif runtime.started then "Running"
				else "Ready",
			message = validationReason
				or "Narrative Runtime is server-authoritative schema and eligibility state only.",
		},
	}
end

function Diagnostics.validate(dependencies: { [string]: any }): (boolean, string?)
	return dependencies.Validation.validate()
end

return Diagnostics

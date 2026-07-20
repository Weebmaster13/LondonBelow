--!strict
-- Diagnostics aggregation for Interaction Runtime Foundation.

local Serialization = require(script.Parent.InteractionSerialization)
local Types = require(script.Parent.InteractionTypes)

local Diagnostics = {}

local function proveSnapshotIsolation(state: any): boolean
	local snapshot = state.inspect()
	snapshot.interactionCount = 999999
	return state.inspect().interactionCount ~= 999999
end

function Diagnostics.capture(runtime: any, dependencies: { [string]: any })
	local state = dependencies.State.inspect()
	local validationOk, validationReason = dependencies.Validation.validate()
	return Serialization.deepCopy({
		initialized = runtime.initialized,
		started = runtime.started,
		lifecycleState = if not runtime.initialized
			then "NotInitialized"
			elseif runtime.started then "Running"
			else "Ready",
		mode = Types.Mode,
		interactionCount = state.interactionCount,
		targetCount = state.targetCount,
		eligibilityCount = state.eligibilityCount,
		intentCount = state.intentCount,
		lockCount = state.lockCount,
		cooldownCount = state.cooldownCount,
		sessionCount = state.sessionCount,
		evidenceCount = state.evidenceCount,
		activeContentionCount = state.activeContentionCount,
		validationFailureCount = state.validationFailureCount,
		recentSanitizedValidationFailures = state.validationFailures,
		snapshotCount = state.snapshotCount,
		runtimeLimits = state.limits,
		serializationPosture = {
			rejectsInstances = true,
			rejectsFunctions = true,
			rejectsThreads = true,
			rejectsUserdata = true,
			rejectsCycles = true,
			rejectsOversizedPayloads = true,
			rejectsOversizedStrings = true,
			rejectsDeepPayloads = true,
			sanitizesDiagnostics = true,
		},
		interactionRuntimePosture = {
			serverAuthoritative = true,
			authorizationBeforeMutation = true,
			validationBeforeMutation = true,
			diagnosticsHealthOnly = true,
			snapshotsIsolated = true,
			noHiddenClientAuthority = true,
			noRemoteCreation = true,
			noPersistence = true,
			noTelemetry = true,
		},
		snapshotIsolationProof = proveSnapshotIsolation(dependencies.State),
		lastSelfChecks = runtime.lastSelfChecks,
		state = state,
		health = {
			healthy = runtime.initialized and validationOk,
			status = if not runtime.initialized
				then "NotInitialized"
				elseif runtime.started then "Running"
				else "Ready",
			message = validationReason
				or "Interaction Runtime is server-authoritative schema state only.",
		},
	})
end

function Diagnostics.validate(dependencies: { [string]: any }): (boolean, string?)
	return dependencies.Validation.validate()
end

return Diagnostics

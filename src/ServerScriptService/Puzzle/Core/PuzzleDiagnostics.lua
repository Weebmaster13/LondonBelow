--!strict
-- Diagnostics aggregation for Puzzle Runtime Foundation.

local Serialization = require(script.Parent.PuzzleSerialization)
local Types = require(script.Parent.PuzzleTypes)

local Diagnostics = {}

local function proveSnapshotIsolation(state: any): boolean
	local snapshot = state.inspect()
	snapshot.puzzleCount = 999999
	return state.inspect().puzzleCount ~= 999999
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
		puzzleCount = state.puzzleCount,
		nodeCount = state.nodeCount,
		graphCount = state.graphCount,
		dependencyCount = state.dependencyCount,
		conditionCount = state.conditionCount,
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
				or "Puzzle Runtime is server-authoritative schema state only.",
		},
	})
end

function Diagnostics.validate(dependencies: { [string]: any }): (boolean, string?)
	return dependencies.Validation.validate()
end

return Diagnostics

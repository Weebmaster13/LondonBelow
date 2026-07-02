--!strict
-- Diagnostics aggregation for Physical Runtime Foundation.

local Serialization = require(script.Parent.PhysicalSerialization)
local Types = require(script.Parent.PhysicalTypes)

local Diagnostics = {}

local function proveSnapshotIsolation(state: any): boolean
	local snapshot = state.inspect()
	snapshot.registeredObjectCount = 999999
	return state.inspect().registeredObjectCount ~= 999999
end

function Diagnostics.capture(runtime: any, dependencies: { [string]: any })
	local state = dependencies.State.inspect()
	local validationOk, validationReason = dependencies.Validation.validate()
	return Serialization.deepCopy({
		initialized = runtime.initialized,
		started = runtime.started,
		mode = Types.Mode,
		registeredObjectCount = state.registeredObjectCount,
		reservationCount = state.reservationCount,
		ownershipCount = state.ownershipCount,
		transformCount = state.transformCount,
		validationFailureCount = state.validationFailureCount,
		validationFailures = state.validationFailures,
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
			deepCopiesPublicState = true,
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
				or "Physical Runtime is server-authoritative schema state only.",
		},
	})
end

function Diagnostics.validate(dependencies: { [string]: any }): (boolean, string?)
	return dependencies.Validation.validate()
end

return Diagnostics

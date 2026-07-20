--!strict

local Serialization = require(script.Parent.EnvironmentalSerialization)
local Types = require(script.Parent.EnvironmentalTypes)

local Diagnostics = {}

function Diagnostics.capture(runtime: any, state: any, families: any)
	local snapshot = state.inspect()
	return Serialization.deepCopy({
		initialized = runtime.initialized,
		started = runtime.started,
		environmentalInteractionRuntimePosture = {
			serverAuthoritative = true,
			usesPhase156InteractionRuntime = true,
			noNewRemotes = true,
			noClientAuthority = true,
			noAnalytics = true,
			noTelemetry = true,
			diagnosticsBounded = true,
			snapshotsIsolated = true,
		},
		familyCount = families.inspect().count,
		objectCount = snapshot.counts.objects,
		activeSessionCount = 0,
		binaryObjectCount = 0,
		inspectableObjectCount = 0,
		actuatorObjectCount = 0,
		transitionCounters = snapshot.counters,
		failureCounters = {
			failures = snapshot.counts.failures,
			lastFailureCode = if snapshot.failures[#snapshot.failures] ~= nil
				then snapshot.failures[#snapshot.failures].code
				else nil,
		},
		dependencyCount = snapshot.counts.bindings,
		lastFailureCode = if snapshot.failures[#snapshot.failures] ~= nil
			then snapshot.failures[#snapshot.failures].code
			else nil,
		runtimeLimits = Types.Limits,
	})
end

return Diagnostics

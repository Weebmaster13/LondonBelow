--!strict

local Serialization = require(script.Parent.EnvironmentalSerialization)
local Types = require(script.Parent.EnvironmentalTypes)

local Snapshots = {}

function Snapshots.capture(state: any, diagnostics: any)
	local snapshot = Serialization.deepCopy({
		environmentalInteractionRuntimeAvailable = true,
		environmentalInteractionRuntimePosture = diagnostics.environmentalInteractionRuntimePosture,
		familyCount = diagnostics.familyCount,
		objectCount = diagnostics.objectCount,
		activeSessionCount = diagnostics.activeSessionCount,
		binaryObjectCount = diagnostics.binaryObjectCount,
		inspectableObjectCount = diagnostics.inspectableObjectCount,
		actuatorObjectCount = diagnostics.actuatorObjectCount,
		transitionCounters = diagnostics.transitionCounters,
		failureCounters = diagnostics.failureCounters,
		dependencyCount = diagnostics.dependencyCount,
		lastFailureCode = diagnostics.lastFailureCode,
		noAnalytics = true,
		noTelemetry = true,
		capturedAt = os.clock(),
		mode = Types.RuntimeName,
	})
	state.recordSnapshot(snapshot)
	return snapshot
end

return Snapshots

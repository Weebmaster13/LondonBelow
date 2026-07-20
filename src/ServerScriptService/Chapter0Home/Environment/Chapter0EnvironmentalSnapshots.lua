--!strict

local ServerScriptService = game:GetService("ServerScriptService")

local Serialization =
	require(ServerScriptService.Interaction.Environmental.EnvironmentalSerialization)

local Types = require(script.Parent.Chapter0EnvironmentalTypes)

local Snapshots = {}

function Snapshots.capture(state: any, diagnostics: any)
	local snapshot = Serialization.deepCopy({
		chapter0EnvironmentalRuntimeAvailable = true,
		chapter0EnvironmentalBindingPosture = diagnostics.chapter0EnvironmentalBindingPosture,
		readinessStatus = diagnostics.readinessStatus,
		stateRevision = diagnostics.stateRevision,
		fixtureCount = diagnostics.fixtureCount,
		bindingCount = diagnostics.bindingCount,
		fixtureFamilies = diagnostics.fixtureFamilies,
		failureCount = diagnostics.failureCount,
		evidenceCount = diagnostics.evidenceCount,
		lastFailureCode = diagnostics.lastFailureCode,
		runtimeLimits = Types.Limits,
		capturedAt = os.clock(),
		mode = Types.RuntimeName,
	})
	state.recordSnapshot(snapshot)
	return snapshot
end

return Snapshots

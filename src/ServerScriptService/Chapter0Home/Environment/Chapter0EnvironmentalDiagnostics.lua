--!strict

local ServerScriptService = game:GetService("ServerScriptService")

local Serialization =
	require(ServerScriptService.Interaction.Environmental.EnvironmentalSerialization)

local Types = require(script.Parent.Chapter0EnvironmentalTypes)

local Diagnostics = {}

function Diagnostics.capture(runtime: any, registry: any)
	local state = registry.inspect()
	return Serialization.deepCopy({
		initialized = runtime.initialized,
		started = runtime.started,
		chapter0EnvironmentalBindingPosture = {
			serverAuthoritative = true,
			chapter0HomeOwned = true,
			usesEnvironmentalInteractionRuntime = true,
			usesInteractionRuntime = true,
			authoredInstanceBinding = true,
			batchRegistration = true,
			rollbackOnFailure = true,
			reconciliationAvailable = true,
			snapshotsIsolated = true,
			diagnosticsBounded = true,
			noNewRemotes = true,
			noClientAuthority = true,
			noPersistence = true,
			noAnalytics = true,
			noTelemetry = true,
			noMonsterAI = true,
			noChapter1Content = true,
		},
		readinessStatus = state.status,
		stateRevision = state.revision,
		fixtureCount = #state.catalog,
		bindingCount = state.counts.bindings,
		fixtureFamilies = state.familyCatalog,
		failureCount = state.counts.failures,
		evidenceCount = state.counts.evidence,
		lastFailureCode = if state.failures[#state.failures] ~= nil
			then state.failures[#state.failures].code
			else nil,
		runtimeLimits = Types.Limits,
	})
end

return Diagnostics

--!strict
-- Snapshot builder for immutable Trigger schema state.

local State = require(script.Parent.TriggerState)
local Types = require(script.Parent.TriggerTypes)

local Snapshots = {}

function Snapshots.capture(lifecycle: any, dependencies: any)
	local state = State.inspect()
	local snapshot = {
		kind = "TriggerRuntimeSnapshot",
		mode = Types.Mode,
		initialized = lifecycle.initialized,
		started = lifecycle.started,
		counts = state.counts,
		schemas = {
			definitions = state.definitions,
			categories = state.categories,
			sources = state.sources,
			targets = state.targets,
			events = state.events,
			filters = state.filters,
			conditions = state.conditions,
			dependencies = state.dependencies,
			groups = state.groups,
			outcomes = state.outcomes,
			audits = state.audits,
		},
		integrityPosture = {
			triggers = "records, not live triggers",
			sources = "metadata, not emitters",
			targets = "metadata, not receivers",
			events = "descriptions, not dispatched events",
			filters = "descriptions, not executed filters",
			conditions = "references, not scored conditions",
			dependencies = "metadata, not blockers",
			groups = "structure, not batches",
			outcomes = "possible future results, not computed facts",
			audits = "review summaries only",
		},
		noExecutionPosture = {
			triggerRun = false,
			triggerDispatch = false,
			eventDispatch = false,
			eventEmission = false,
			callbackRun = false,
			listenerRun = false,
			liveListenerState = false,
			conditionScoring = false,
			ruleScoring = false,
			ruleRun = false,
			ruleEngineRun = false,
			eventGraphRun = false,
			runtimeGraphRun = false,
			conditionRuntimeRun = false,
			scriptSurface = false,
			stateChange = false,
			gameplayRun = false,
			schedulerRun = false,
			lifecycleRun = false,
			runtimeOrchestration = false,
			workspaceChange = false,
			remotes = false,
			clientAuthority = false,
			chapterContent = false,
		},
		validationFailures = state.validationFailures,
	}
	State.recordSnapshot(snapshot)
	return dependencies.Serialization.deepCopy(snapshot)
end

return Snapshots

--!strict
-- Snapshot builder for immutable Condition schema state.

local State = require(script.Parent.ConditionState)
local Types = require(script.Parent.ConditionTypes)

local Snapshots = {}

function Snapshots.capture(lifecycle: any, dependencies: any)
	local state = State.inspect()
	local snapshot = {
		kind = "ConditionRuntimeSnapshot",
		mode = Types.Mode,
		initialized = lifecycle.initialized,
		started = lifecycle.started,
		counts = state.counts,
		schemas = {
			definitions = state.definitions,
			categories = state.categories,
			expressions = state.expressions,
			operands = state.operands,
			operators = state.operators,
			groups = state.groups,
			dependencies = state.dependencies,
			states = state.states,
			outcomes = state.outcomes,
			audits = state.audits,
		},
		integrityPosture = {
			conditions = "records, not decisions",
			categories = "classification metadata",
			expressions = "descriptions, not computations",
			operators = "metadata, not functions",
			operands = "schema values, not live inputs",
			groups = "logical structure, not active branching",
			dependencies = "metadata, not blockers",
			states = "descriptions, not mutated state",
			outcomes = "possible future results, not computed facts",
			audits = "review summaries only",
		},
		noExecutionPosture = {
			conditionScoring = false,
			expressionScoring = false,
			booleanRun = false,
			logicRun = false,
			branchingRun = false,
			scriptSurface = false,
			ruleRun = false,
			triggerRun = false,
			gameplayRun = false,
			schedulerRun = false,
			lifecycleRun = false,
			eventGraphRun = false,
			runtimeGraphRun = false,
			ruleEngineRun = false,
			runtimeOrchestration = false,
			stateChange = false,
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

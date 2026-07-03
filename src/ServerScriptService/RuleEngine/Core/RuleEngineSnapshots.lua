--!strict
-- Snapshot builder for immutable Rule Engine schema state.

local State = require(script.Parent.RuleEngineState)
local Types = require(script.Parent.RuleEngineTypes)

local Snapshots = {}

function Snapshots.capture(lifecycle: any, dependencies: any)
	local state = State.inspect()
	local snapshot = {
		kind = "RuleEngineSnapshot",
		mode = Types.Mode,
		initialized = lifecycle.initialized,
		started = lifecycle.started,
		counts = state.counts,
		schemas = {
			rules = state.rules,
			categories = state.categories,
			predicates = state.predicates,
			constraints = state.constraints,
			permissions = state.permissions,
			policies = state.policies,
			groups = state.groups,
			dependencies = state.dependencies,
			outcomes = state.outcomes,
			audits = state.audits,
		},
		integrityPosture = {
			rules = "records, not executable rules",
			categories = "classifications, not enforcement domains",
			predicates = "schemas, not evaluated conditions",
			constraints = "schemas, not active limits",
			permissions = "declarations, not grants or denials",
			policies = "schemas, not policy execution",
			groups = "collections, not execution batches",
			dependencies = "metadata, not blockers",
			outcomes = "possible result schemas, not computed results",
			audits = "review summaries, not enforcement",
		},
		noExecutionPosture = {
			liveRuleEvaluation = false,
			ruleEnforcement = false,
			predicateExecution = false,
			permissionGranting = false,
			permissionDenial = false,
			policyExecution = false,
			moderation = false,
			antiCheatEnforcement = false,
			runtimeOrchestration = false,
			gameplayExecution = false,
			workspaceMutation = false,
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

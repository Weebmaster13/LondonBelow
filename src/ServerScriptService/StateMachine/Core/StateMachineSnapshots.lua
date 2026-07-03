--!strict
-- Snapshot builder for immutable State Machine schema state.

local State = require(script.Parent.StateMachineState)
local Types = require(script.Parent.StateMachineTypes)

local Snapshots = {}

function Snapshots.capture(lifecycle: any, dependencies: any)
	local state = State.inspect()
	local snapshot = {
		kind = "StateMachineRuntimeSnapshot",
		mode = Types.Mode,
		initialized = lifecycle.initialized,
		started = lifecycle.started,
		counts = state.counts,
		schemas = {
			definitions = state.definitions,
			states = state.states,
			transitions = state.transitions,
			guards = state.guards,
			inputs = state.inputs,
			outputs = state.outputs,
			groups = state.groups,
			dependencies = state.dependencies,
			outcomes = state.outcomes,
			audits = state.audits,
		},
		integrityPosture = {
			stateMachines = "records, not executable machines",
			states = "descriptions, not live states",
			transitions = "descriptions, not active transitions",
			guards = "references, not scored guards",
			inputs = "descriptions, not consumed inputs",
			outputs = "descriptions, not emitted outputs",
			groups = "structure only",
			dependencies = "metadata only",
			outcomes = "possible future results only",
			audits = "review summaries only",
		},
		noExecutionPosture = {
			stateMachineRun = false,
			transitionRun = false,
			liveStateChange = false,
			guardScoring = false,
			inputUse = false,
			outputEmit = false,
			gameplayStateRun = false,
			triggerRun = false,
			conditionScoring = false,
			ruleScoring = false,
			eventDispatch = false,
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

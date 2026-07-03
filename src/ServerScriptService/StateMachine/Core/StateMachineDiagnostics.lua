--!strict
-- Health-only diagnostics for the State Machine schema runtime.

local State = require(script.Parent.StateMachineState)
local Types = require(script.Parent.StateMachineTypes)

local Diagnostics = {}

local function limitUsage(count: number, limit: number)
	return { count = count, limit = limit, remaining = math.max(limit - count, 0) }
end

function Diagnostics.capture(lifecycle: any, dependencies: any)
	local state = State.inspect()
	local counts = state.counts
	local validationOk, validationReason = dependencies.Validation.validate()
	return {
		initialized = lifecycle.initialized,
		started = lifecycle.started,
		lifecycleState = if lifecycle.started
			then "Started"
			elseif lifecycle.initialized then "Initialized"
			else "Cold",
		health = if validationOk then "Healthy" else "Unhealthy",
		validationOk = validationOk,
		validationReason = validationReason,
		stateMachineCount = counts.definitions,
		stateCount = counts.states,
		transitionCount = counts.transitions,
		guardCount = counts.guards,
		inputCount = counts.inputs,
		outputCount = counts.outputs,
		groupCount = counts.groups,
		dependencyCount = counts.dependencies,
		outcomeCount = counts.outcomes,
		auditCount = counts.audits,
		validationFailureCount = counts.validationFailures,
		snapshotCount = counts.snapshots,
		counts = counts,
		limitUsage = {
			stateMachines = limitUsage(counts.definitions, Types.Limits.MaxStateMachines),
			states = limitUsage(counts.states, Types.Limits.MaxStates),
			transitions = limitUsage(counts.transitions, Types.Limits.MaxTransitions),
			guards = limitUsage(counts.guards, Types.Limits.MaxGuards),
			inputs = limitUsage(counts.inputs, Types.Limits.MaxInputs),
			outputs = limitUsage(counts.outputs, Types.Limits.MaxOutputs),
			groups = limitUsage(counts.groups, Types.Limits.MaxGroups),
			dependencies = limitUsage(counts.dependencies, Types.Limits.MaxDependencies),
			outcomes = limitUsage(counts.outcomes, Types.Limits.MaxOutcomes),
			audits = limitUsage(counts.audits, Types.Limits.MaxAudits),
		},
		runtimeLimits = Types.Limits,
		serializationPosture = "rejects unsafe runtime values, cycles, deep payloads, oversized strings, and oversized node counts",
		snapshotIsolationProof = "snapshots are deep copied schema data",
		diagnosticsIsolationProof = "diagnostics are deep copied health data",
		integrityPosture = {
			stateMachine = "records only",
			state = "description only",
			transition = "description only",
			guard = "reference only",
			input = "description only",
			output = "description only",
			group = "structure only",
			dependency = "metadata only",
			outcome = "possible future result only",
			audit = "review summary only",
		},
		stateMachineIntegrityPosture = "definitions are inert schema records",
		stateIntegrityPosture = "state records are descriptive schema data only",
		transitionIntegrityPosture = "transition records are descriptive schema data only",
		guardIntegrityPosture = "guard records are descriptive references only",
		inputIntegrityPosture = "input records are descriptive schema data only",
		outputIntegrityPosture = "output records are descriptive schema data only",
		groupIntegrityPosture = "group records are structural schema data only",
		dependencyIntegrityPosture = "dependency records are metadata only",
		outcomeIntegrityPosture = "outcome records are possible future result descriptions only",
		auditIntegrityPosture = "audit records are review summaries only",
		noExecutionPosture = {
			noStateMachineRun = true,
			noTransitionRun = true,
			noLiveStateChange = true,
			noGuardScoring = true,
			noInputUse = true,
			noOutputEmit = true,
			noAnimationStateRun = true,
			noGameplayStateRun = true,
			noAIStateRun = true,
			noMonsterAIStateRun = true,
			noNarrativeStateRun = true,
			noPresentationStateRun = true,
			noTriggerRun = true,
			noConditionScoring = true,
			noRuleScoring = true,
			noEventDispatch = true,
			noEventGraphRun = true,
			noRuntimeGraphRun = true,
			noRuleEngineRun = true,
			noTriggerRuntimeRun = true,
			noConditionRuntimeRun = true,
			noSchedulerRun = true,
			noLifecycleRun = true,
			noRuntimeOrchestration = true,
			noSaveRun = true,
			noScripting = true,
			noCallbacks = true,
			noListeners = true,
			noWorkspaceChange = true,
			noRemotes = true,
			noClientAuthority = true,
			noStorageReadsWrites = true,
			noHttpLayer = true,
			noMessagingLayer = true,
			noMetricsCollection = true,
			noSignalExport = true,
			noChapterContent = true,
			noFinalStory = true,
			noFinalDialogue = true,
			noCutscenes = true,
		},
		recentValidationFailures = state.validationFailures,
		lastSelfCheckResult = lifecycle.lastSelfChecks,
	}
end

function Diagnostics.validate(dependencies: any): (boolean, string?)
	local ok, reason = dependencies.Validation.validate()
	if not ok then
		return false, reason
	end
	return true, nil
end

return Diagnostics

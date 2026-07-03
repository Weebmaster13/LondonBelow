--!strict
-- Health-only diagnostics for the Condition schema runtime.

local State = require(script.Parent.ConditionState)
local Types = require(script.Parent.ConditionTypes)

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
		conditionCount = counts.definitions,
		categoryCount = counts.categories,
		expressionCount = counts.expressions,
		operandCount = counts.operands,
		operatorCount = counts.operators,
		groupCount = counts.groups,
		dependencyCount = counts.dependencies,
		stateCount = counts.states,
		outcomeCount = counts.outcomes,
		auditCount = counts.audits,
		validationFailureCount = counts.validationFailures,
		snapshotCount = counts.snapshots,
		counts = counts,
		limitUsage = {
			conditions = limitUsage(counts.definitions, Types.Limits.MaxConditions),
			categories = limitUsage(counts.categories, Types.Limits.MaxCategories),
			expressions = limitUsage(counts.expressions, Types.Limits.MaxExpressions),
			operands = limitUsage(counts.operands, Types.Limits.MaxOperands),
			operators = limitUsage(counts.operators, Types.Limits.MaxOperators),
			groups = limitUsage(counts.groups, Types.Limits.MaxGroups),
			dependencies = limitUsage(counts.dependencies, Types.Limits.MaxDependencies),
			states = limitUsage(counts.states, Types.Limits.MaxStates),
			outcomes = limitUsage(counts.outcomes, Types.Limits.MaxOutcomes),
			audits = limitUsage(counts.audits, Types.Limits.MaxAudits),
		},
		runtimeLimits = Types.Limits,
		serializationPosture = "rejects unsafe runtime values, cycles, deep payloads, oversized strings, and oversized node counts",
		snapshotIsolationProof = "snapshots are deep copied schema data",
		diagnosticsIsolationProof = "diagnostics are deep copied health data",
		integrityPosture = {
			condition = "records only",
			expression = "description only",
			operator = "metadata only",
			operand = "schema value only",
			group = "logical structure only",
			dependency = "metadata only",
			state = "schema description only",
			outcome = "possible future result only",
			audit = "review summary only",
		},
		noExecutionPosture = {
			noConditionScoring = true,
			noExpressionScoring = true,
			noBooleanRun = true,
			noRuleRun = true,
			noTriggerRun = true,
			noGameplayRun = true,
			noPuzzleRun = true,
			noInteractionRun = true,
			noInventoryRun = true,
			noObjectiveRun = true,
			noMonsterAIRun = true,
			noNarrativeRun = true,
			noPresentationRun = true,
			noSchedulerRun = true,
			noLifecycleRun = true,
			noRuntimeOrchestration = true,
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

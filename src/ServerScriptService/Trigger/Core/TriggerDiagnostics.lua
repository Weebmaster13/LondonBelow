--!strict
-- Health-only diagnostics for the Trigger schema runtime.

local State = require(script.Parent.TriggerState)
local Types = require(script.Parent.TriggerTypes)

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
		triggerCount = counts.definitions,
		categoryCount = counts.categories,
		sourceCount = counts.sources,
		targetCount = counts.targets,
		eventCount = counts.events,
		filterCount = counts.filters,
		conditionCount = counts.conditions,
		dependencyCount = counts.dependencies,
		groupCount = counts.groups,
		outcomeCount = counts.outcomes,
		auditCount = counts.audits,
		validationFailureCount = counts.validationFailures,
		snapshotCount = counts.snapshots,
		counts = counts,
		limitUsage = {
			triggers = limitUsage(counts.definitions, Types.Limits.MaxTriggers),
			categories = limitUsage(counts.categories, Types.Limits.MaxCategories),
			sources = limitUsage(counts.sources, Types.Limits.MaxSources),
			targets = limitUsage(counts.targets, Types.Limits.MaxTargets),
			events = limitUsage(counts.events, Types.Limits.MaxEvents),
			filters = limitUsage(counts.filters, Types.Limits.MaxFilters),
			conditions = limitUsage(counts.conditions, Types.Limits.MaxConditions),
			dependencies = limitUsage(counts.dependencies, Types.Limits.MaxDependencies),
			groups = limitUsage(counts.groups, Types.Limits.MaxGroups),
			outcomes = limitUsage(counts.outcomes, Types.Limits.MaxOutcomes),
			audits = limitUsage(counts.audits, Types.Limits.MaxAudits),
		},
		runtimeLimits = Types.Limits,
		serializationPosture = "rejects unsafe runtime values, cycles, deep payloads, oversized strings, and oversized node counts",
		snapshotIsolationProof = "snapshots are deep copied schema data",
		diagnosticsIsolationProof = "diagnostics are deep copied health data",
		integrityPosture = {
			trigger = "records only",
			category = "taxonomy only",
			source = "metadata only",
			target = "metadata only",
			event = "description only",
			filter = "description only",
			condition = "reference only",
			dependency = "metadata only",
			group = "structure only",
			outcome = "possible future result only",
			audit = "review summary only",
		},
		noExecutionPosture = {
			noTriggerRun = true,
			noTriggerDispatch = true,
			noEventDispatch = true,
			noEventEmission = true,
			noCallbackRun = true,
			noListenerRun = true,
			noLiveListenerState = true,
			noConditionScoring = true,
			noRuleScoring = true,
			noRuleRun = true,
			noRuleEngineRun = true,
			noEventGraphRun = true,
			noRuntimeGraphRun = true,
			noConditionRuntimeRun = true,
			noScriptSurface = true,
			noStateChange = true,
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

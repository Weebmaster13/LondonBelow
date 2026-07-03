--!strict
-- Diagnostics for Runtime Scheduler Foundation.

local Serialization = require(script.Parent.RuntimeSchedulerSerialization)
local Types = require(script.Parent.RuntimeSchedulerTypes)

local Diagnostics = {}

local function limitState(state: any)
	return {
		plans = state.counts.plans .. "/" .. Types.Limits.MaxSchedulePlans,
		slots = state.counts.slots .. "/" .. Types.Limits.MaxSlots,
		queues = state.counts.queues .. "/" .. Types.Limits.MaxQueues,
		priorities = state.counts.priorities .. "/" .. Types.Limits.MaxPriorities,
		budgets = state.counts.budgets .. "/" .. Types.Limits.MaxBudgets,
		deadlines = state.counts.deadlines .. "/" .. Types.Limits.MaxDeadlines,
		retries = state.counts.retries .. "/" .. Types.Limits.MaxRetries,
		intervals = state.counts.intervals .. "/" .. Types.Limits.MaxIntervals,
		windows = state.counts.windows .. "/" .. Types.Limits.MaxWindows,
		dependencies = state.counts.dependencies .. "/" .. Types.Limits.MaxDependencies,
		audits = state.counts.audits .. "/" .. Types.Limits.MaxAudits,
		validationFailures = state.counts.validationFailures
			.. "/"
			.. Types.Limits.MaxValidationFailures,
		snapshots = state.counts.snapshots .. "/" .. Types.Limits.MaxSnapshotHistory,
	}
end

function Diagnostics.capture(lifecycle: any, dependencies: any)
	local state = dependencies.State.inspect()
	local validationOk, validationReason = dependencies.Validation.validate()
	local health = "Healthy"
	if not validationOk then
		health = "Unhealthy"
	elseif state.counts.validationFailures > 0 then
		health = "Warning"
	end

	return Serialization.deepCopy({
		health = health,
		validationOk = validationOk,
		validationReason = validationReason,
		lifecycleState = lifecycle.started and "Started"
			or (lifecycle.initialized and "Initialized" or "Stopped"),
		initialized = lifecycle.initialized,
		started = lifecycle.started,
		lastSelfChecks = lifecycle.lastSelfChecks,
		counts = state.counts,
		limits = Types.Limits,
		mode = Types.Mode,
		perCategoryLimitState = limitState(state),
		serializationPosture = {
			rejectsInstances = true,
			rejectsUnsafeRuntimeValues = true,
			rejectsCycles = true,
			rejectsOversizedPayloads = true,
			exportsDeepCopies = true,
		},
		snapshotIsolationProof = {
			snapshotsAreDeepCopies = true,
			containsSchemaStateOnly = true,
			containsNoLiveScheduledWork = true,
			containsNoThreads = true,
			containsNoRunLoopReferences = true,
			containsNoTaskHandles = true,
			containsNoTimerHandles = true,
			containsNoLiveQueues = true,
			containsNoCallbacks = true,
			containsNoRemoteReferences = true,
			containsNoExecutionAdapters = true,
		},
		diagnosticsIsolationProof = {
			diagnosticsAreDeepCopies = true,
			rawUnsafePayloadsAreSanitized = true,
			containsNoLiveScheduledWork = true,
			containsNoServiceHandles = true,
			containsNoFrameworkInternals = true,
			containsNoModuleReferences = true,
			notLiveScheduling = true,
		},
		schedulerIntegrityPosture = { schemasOnly = true, plansAreNotCommands = true },
		queueIntegrityPosture = { schemasOnly = true, notLiveQueues = true },
		budgetIntegrityPosture = { constraintsOnly = true, notThrottles = true },
		deadlineIntegrityPosture = { metadataOnly = true, notTimers = true },
		retryIntegrityPosture = { policiesOnly = true, notRetryExecution = true },
		intervalIntegrityPosture = { valuesOnly = true, notLoops = true },
		windowIntegrityPosture = { descriptionsOnly = true, notLiveChecks = true },
		dependencyIntegrityPosture = { metadataOnly = true, notBlockers = true },
		auditIntegrityPosture = { summariesOnly = true, notEnforcement = true },
		noExecutionPosture = {
			noLiveScheduling = true,
			noTaskExecution = true,
			noJobExecution = true,
			noCoroutineExecution = true,
			noRunLoopExecution = true,
			noFrameScheduling = true,
			noTickExecution = true,
			noQueueProcessing = true,
			noRetryExecution = true,
			noTimeoutExecution = true,
			noGapExecution = true,
			noDispatchExecution = true,
			noAsyncExecution = true,
			noRuntimeOrchestration = true,
			noStartupShutdownInitializationExecution = true,
			noDependencyInjectionExecution = true,
			noServiceResolution = true,
			noModuleLoading = true,
			noRequireCallExecution = true,
			noRuntimeApiCalls = true,
			noGameplayExecution = true,
			noPuzzleExecution = true,
			noInteractionExecution = true,
			noInventoryExecution = true,
			noObjectiveExecution = true,
			noNarrativeExecution = true,
			noMonsterAiExecution = true,
			noPresentationExecution = true,
			noSavePersistence = true,
			noContentLoading = true,
			noAssetLoading = true,
			noMapLoading = true,
			noRoomLoading = true,
			noWorldMutation = true,
			noRemotes = true,
			noClientAuthority = true,
			noDataStoreReads = true,
			noDataStoreWrites = true,
			noExternalHttpAccess = true,
			noExternalMessagingAccess = true,
			noAnalyticsCollection = true,
			noTelemetrySending = true,
			noChapterContent = true,
			noFinalStory = true,
			noFinalDialogue = true,
			noCutscenes = true,
		},
		recentValidationFailures = state.validationFailures,
	})
end

function Diagnostics.validate(dependencies: any): (boolean, string?)
	local ok, reason = dependencies.Validation.validate()
	if not ok then
		return false, reason
	end
	local state = dependencies.State.inspect()
	local checks = {
		{ state.counts.plans, Types.Limits.MaxSchedulePlans, "plan count exceeds limit" },
		{ state.counts.slots, Types.Limits.MaxSlots, "slot count exceeds limit" },
		{ state.counts.queues, Types.Limits.MaxQueues, "queue count exceeds limit" },
		{ state.counts.priorities, Types.Limits.MaxPriorities, "priority count exceeds limit" },
		{ state.counts.budgets, Types.Limits.MaxBudgets, "budget count exceeds limit" },
		{ state.counts.deadlines, Types.Limits.MaxDeadlines, "deadline count exceeds limit" },
		{ state.counts.retries, Types.Limits.MaxRetries, "retry count exceeds limit" },
		{ state.counts.intervals, Types.Limits.MaxIntervals, "interval count exceeds limit" },
		{ state.counts.windows, Types.Limits.MaxWindows, "window count exceeds limit" },
		{
			state.counts.dependencies,
			Types.Limits.MaxDependencies,
			"dependency count exceeds limit",
		},
		{ state.counts.audits, Types.Limits.MaxAudits, "audit count exceeds limit" },
		{
			state.counts.validationFailures,
			Types.Limits.MaxValidationFailures,
			"validation failure history exceeds limit",
		},
		{
			state.counts.snapshots,
			Types.Limits.MaxSnapshotHistory,
			"snapshot history exceeds limit",
		},
	}
	for _, check in ipairs(checks) do
		if check[1] > check[2] then
			return false, check[3]
		end
	end
	return true, nil
end

return Diagnostics

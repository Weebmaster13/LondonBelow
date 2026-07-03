--!strict
-- Diagnostics for Runtime Lifecycle Foundation.

local Serialization = require(script.Parent.RuntimeLifecycleSerialization)
local Types = require(script.Parent.RuntimeLifecycleTypes)

local Diagnostics = {}

local function limitState(state: any)
	return {
		lifecycleStates = state.counts.lifecycleStates .. "/" .. Types.Limits.MaxLifecycleStates,
		transitions = state.counts.transitions .. "/" .. Types.Limits.MaxTransitions,
		policies = state.counts.policies .. "/" .. Types.Limits.MaxPolicies,
		guards = state.counts.guards .. "/" .. Types.Limits.MaxGuards,
		events = state.counts.events .. "/" .. Types.Limits.MaxEvents,
		failures = state.counts.failures .. "/" .. Types.Limits.MaxFailures,
		recoveries = state.counts.recoveries .. "/" .. Types.Limits.MaxRecoveries,
		checkpoints = state.counts.checkpoints .. "/" .. Types.Limits.MaxCheckpoints,
		audits = state.counts.audits .. "/" .. Types.Limits.MaxAudits,
		compatibilities = state.counts.compatibilities
			.. "/"
			.. Types.Limits.MaxCompatibilityRecords,
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
			containsNoLiveRuntimeObjects = true,
			containsNoFrameworkReferences = true,
			containsNoRuntimeGraphReferences = true,
			containsNoServiceReferences = true,
			containsNoModuleReferences = true,
			containsNoRequireHandles = true,
			containsNoRemoteReferences = true,
			containsNoCallbacks = true,
			containsNoExecutionAdapters = true,
		},
		diagnosticsIsolationProof = {
			diagnosticsAreDeepCopies = true,
			rawUnsafePayloadsAreSanitized = true,
			containsNoLiveLifecycleState = true,
			containsNoServiceHandles = true,
			containsNoFrameworkInternals = true,
			containsNoRuntimeGraphInternals = true,
			notLiveOrchestration = true,
			notServiceManagement = true,
		},
		lifecycleIntegrityPosture = { recordsOnly = true, notLiveRuntimeStates = true },
		transitionIntegrityPosture = { descriptionsOnly = true, notStateChanges = true },
		policyIntegrityPosture = { constraintsOnly = true, notEnforcement = true },
		guardIntegrityPosture = { requirementsOnly = true, notLiveChecks = true },
		failureIntegrityPosture = { schemasOnly = true, notFailureHandlers = true },
		recoveryIntegrityPosture = { schemasOnly = true, notRecoveryExecution = true },
		checkpointIntegrityPosture = { metadataOnly = true, notSavePersistence = true },
		auditIntegrityPosture = { summariesOnly = true, notEnforcement = true },
		compatibilityIntegrityPosture = { metadataOnly = true, notMigrations = true },
		noExecutionPosture = {
			noStartupExecution = true,
			noShutdownExecution = true,
			noInitializationExecution = true,
			noRestartExecution = true,
			noRecoveryExecution = true,
			noPauseResumeExecution = true,
			noUnloadReloadExecution = true,
			noLiveServiceManagement = true,
			noFrameworkReplacement = true,
			noFrameworkMutation = true,
			noRuntimeGraphOwnership = true,
			noDependencyInjectionExecution = true,
			noServiceResolution = true,
			noModuleLoading = true,
			noRequireCallExecution = true,
			noRuntimeApiCalls = true,
			noLifecycleExecution = true,
			noOrchestrationExecution = true,
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
		{
			state.counts.lifecycleStates,
			Types.Limits.MaxLifecycleStates,
			"lifecycle state count exceeds limit",
		},
		{ state.counts.transitions, Types.Limits.MaxTransitions, "transition count exceeds limit" },
		{ state.counts.policies, Types.Limits.MaxPolicies, "policy count exceeds limit" },
		{ state.counts.guards, Types.Limits.MaxGuards, "guard count exceeds limit" },
		{ state.counts.events, Types.Limits.MaxEvents, "event count exceeds limit" },
		{ state.counts.failures, Types.Limits.MaxFailures, "failure count exceeds limit" },
		{ state.counts.recoveries, Types.Limits.MaxRecoveries, "recovery count exceeds limit" },
		{ state.counts.checkpoints, Types.Limits.MaxCheckpoints, "checkpoint count exceeds limit" },
		{ state.counts.audits, Types.Limits.MaxAudits, "audit count exceeds limit" },
		{
			state.counts.compatibilities,
			Types.Limits.MaxCompatibilityRecords,
			"compatibility count exceeds limit",
		},
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

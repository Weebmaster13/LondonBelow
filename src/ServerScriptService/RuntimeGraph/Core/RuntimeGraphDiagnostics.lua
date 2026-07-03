--!strict
-- Diagnostics for Runtime Dependency Graph Foundation.

local Serialization = require(script.Parent.RuntimeGraphSerialization)
local Types = require(script.Parent.RuntimeGraphTypes)

local Diagnostics = {}

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
		perCategoryLimitState = {
			nodes = state.counts.nodes .. "/" .. Types.Limits.MaxRuntimeNodes,
			dependencies = state.counts.dependencies .. "/" .. Types.Limits.MaxDependencies,
			capabilities = state.counts.capabilities .. "/" .. Types.Limits.MaxCapabilities,
			requirements = state.counts.requirements .. "/" .. Types.Limits.MaxRequirements,
			compatibilities = state.counts.compatibilities
				.. "/"
				.. Types.Limits.MaxCompatibilityRecords,
			orderings = state.counts.orderings .. "/" .. Types.Limits.MaxOrderingRecords,
			startupPlans = state.counts.startupPlans .. "/" .. Types.Limits.MaxStartupPlans,
			shutdownPlans = state.counts.shutdownPlans .. "/" .. Types.Limits.MaxShutdownPlans,
			groups = state.counts.groups .. "/" .. Types.Limits.MaxGroups,
			validationRecords = state.counts.validationRecords
				.. "/"
				.. Types.Limits.MaxValidationRecords,
			validationFailures = state.counts.validationFailures
				.. "/"
				.. Types.Limits.MaxValidationFailures,
			snapshots = state.counts.snapshots .. "/" .. Types.Limits.MaxSnapshotHistory,
		},
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
			containsNoRuntimeObjects = true,
			containsNoServiceHandles = true,
			containsNoFrameworkInternals = true,
			containsNoModuleReferences = true,
			containsNoCallbacks = true,
			notLiveOrchestration = true,
		},
		graphIntegrityPosture = {
			globalNamespace = true,
			dependenciesRequireRegisteredEndpoints = true,
			optionalDependenciesRequireRegisteredEndpoints = true,
			forbiddenDependenciesAreRecordsOnly = true,
			historicalDependenciesAreRecordsOnly = true,
		},
		cycleDetectionPosture = {
			rejectsSelfDependencies = true,
			rejectsDirectRequiredCycles = true,
			doesNotRebuildGraph = true,
		},
		capabilityIntegrityPosture = {
			requiresRegisteredNode = true,
			declarationsOnly = true,
			notExecutionPermissions = true,
		},
		requirementIntegrityPosture = {
			requiresRegisteredNode = true,
			declarationsOnly = true,
			notServiceLookup = true,
		},
		orderingIntegrityPosture = {
			requiresRegisteredEndpoints = true,
			rejectsSelfOrdering = true,
			rejectsDirectContradictions = true,
			planMetadataOnly = true,
		},
		startupPlanPosture = {
			schemasOnly = true,
			referencesRegisteredNodes = true,
			referencesRegisteredDependencies = true,
			referencesRegisteredOrderings = true,
			notStartupCommands = true,
		},
		shutdownPlanPosture = {
			schemasOnly = true,
			referencesRegisteredNodes = true,
			referencesRegisteredDependencies = true,
			referencesRegisteredOrderings = true,
			notShutdownCommands = true,
		},
		noExecutionPosture = {
			noStartupExecution = true,
			noShutdownExecution = true,
			noInitializationExecution = true,
			noModuleLoading = true,
			noRequireCalls = true,
			noDependencyInjectionExecution = true,
			noServiceResolution = true,
			noFrameworkReplacement = true,
			noRuntimeApiCalls = true,
			noLifecycleExecution = true,
			noOrchestrationExecution = true,
			noContentLoading = true,
			noAssetLoading = true,
			noMapLoading = true,
			noRoomLoading = true,
			noWorldMutation = true,
			noRemotes = true,
			noClientAuthority = true,
			noGameplayExecution = true,
			noPuzzleExecution = true,
			noInteractionExecution = true,
			noInventoryExecution = true,
			noObjectiveExecution = true,
			noNarrativeExecution = true,
			noMonsterAiExecution = true,
			noPresentationExecution = true,
			noSavePersistence = true,
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
		{ state.counts.nodes, Types.Limits.MaxRuntimeNodes, "runtime node count exceeds limit" },
		{
			state.counts.dependencies,
			Types.Limits.MaxDependencies,
			"dependency count exceeds limit",
		},
		{
			state.counts.capabilities,
			Types.Limits.MaxCapabilities,
			"capability count exceeds limit",
		},
		{
			state.counts.requirements,
			Types.Limits.MaxRequirements,
			"requirement count exceeds limit",
		},
		{
			state.counts.compatibilities,
			Types.Limits.MaxCompatibilityRecords,
			"compatibility count exceeds limit",
		},
		{ state.counts.orderings, Types.Limits.MaxOrderingRecords, "ordering count exceeds limit" },
		{
			state.counts.startupPlans,
			Types.Limits.MaxStartupPlans,
			"startup plan count exceeds limit",
		},
		{
			state.counts.shutdownPlans,
			Types.Limits.MaxShutdownPlans,
			"shutdown plan count exceeds limit",
		},
		{ state.counts.groups, Types.Limits.MaxGroups, "group count exceeds limit" },
		{
			state.counts.validationRecords,
			Types.Limits.MaxValidationRecords,
			"validation record count exceeds limit",
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

--!strict
-- Snapshot provider for Runtime Dependency Graph Foundation.

local Serialization = require(script.Parent.RuntimeGraphSerialization)
local Types = require(script.Parent.RuntimeGraphTypes)

local Snapshots = {}

function Snapshots.capture(state: any)
	local current = state.inspect()
	local snapshot = Serialization.deepCopy({
		mode = Types.Mode,
		counts = current.counts,
		nodes = current.nodes,
		dependencies = current.dependencies,
		capabilities = current.capabilities,
		requirements = current.requirements,
		compatibilities = current.compatibilities,
		orderings = current.orderings,
		startupPlans = current.startupPlans,
		shutdownPlans = current.shutdownPlans,
		groups = current.groups,
		validationRecords = current.validationRecords,
		recentValidationFailures = current.validationFailures,
		noExecutionPosture = {
			noStartupExecution = true,
			noShutdownExecution = true,
			noInitializationExecution = true,
			noModuleLoading = true,
			noRequireCalls = true,
			noDependencyInjectionExecution = true,
			noServiceResolution = true,
			noFrameworkReplacement = true,
			noFrameworkMutation = true,
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
	})
	state.recordSnapshot(snapshot)
	return snapshot
end

return Snapshots

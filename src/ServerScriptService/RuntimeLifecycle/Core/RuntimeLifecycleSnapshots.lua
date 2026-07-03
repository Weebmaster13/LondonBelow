--!strict
-- Snapshot provider for Runtime Lifecycle Foundation.

local Serialization = require(script.Parent.RuntimeLifecycleSerialization)
local Types = require(script.Parent.RuntimeLifecycleTypes)

local Snapshots = {}

function Snapshots.capture(state: any)
	local current = state.inspect()
	local snapshot = Serialization.deepCopy({
		mode = Types.Mode,
		counts = current.counts,
		lifecycleStates = current.lifecycleStates,
		transitions = current.transitions,
		policies = current.policies,
		guards = current.guards,
		events = current.events,
		failures = current.failures,
		recoveries = current.recoveries,
		checkpoints = current.checkpoints,
		audits = current.audits,
		compatibilities = current.compatibilities,
		recentValidationFailures = current.validationFailures,
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
	})
	state.recordSnapshot(snapshot)
	return snapshot
end

return Snapshots

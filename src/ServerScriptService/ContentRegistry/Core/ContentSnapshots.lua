--!strict
-- Snapshot provider for Content Registry Runtime Foundation.

local Serialization = require(script.Parent.ContentSerialization)
local Types = require(script.Parent.ContentTypes)

local Snapshots = {}

function Snapshots.capture(state: any)
	local current = state.inspect()
	local snapshot = Serialization.deepCopy({
		mode = Types.Mode,
		counts = current.counts,
		contentDefinitions = current.contentDefinitions,
		categories = current.categories,
		references = current.references,
		dependencies = current.dependencies,
		packages = current.packages,
		versions = current.versions,
		tags = current.tags,
		recentValidationFailures = current.validationFailures,
		noExecutionPosture = {
			noChapterContent = true,
			noChapter0Content = true,
			noFinalStory = true,
			noFinalDialogue = true,
			noFinalRoomLayouts = true,
			noFinalPuzzles = true,
			noFinalItems = true,
			noFinalObjectives = true,
			noFinalMonsterBehavior = true,
			noAssetLoading = true,
			noMapLoading = true,
			noRoomLoading = true,
			noContentStreaming = true,
			noContentSpawning = true,
			noPackageLoading = true,
			noContentAuthoring = true,
			noWorldMutation = true,
			noGameplayExecution = true,
			noPuzzleExecution = true,
			noInteractionExecution = true,
			noInventoryExecution = true,
			noObjectiveCompletion = true,
			noNarrativeExecution = true,
			noSavePersistence = true,
			noDataStoreReads = true,
			noDataStoreWrites = true,
			noExternalHttpAccess = true,
			noExternalMessagingAccess = true,
			noRemotes = true,
			noClientAuthority = true,
			noAnalyticsCollection = true,
			noTelemetrySending = true,
		},
	})
	state.recordSnapshot(snapshot)
	return snapshot
end

return Snapshots

--!strict

local Serialization = require(script.Parent.Chapter0HomeSerialization)
local Types = require(script.Parent.Chapter0HomeTypes)

local Snapshots = {}

function Snapshots.capture(state: any, definition: Types.ChapterDefinition)
	local snapshot = state.snapshot()

	return {
		provider = Types.SnapshotProviderName,
		chapterId = definition.chapterId,
		status = snapshot.status,
		roomCount = #definition.rooms,
		interactionCount = #definition.interactions,
		atmosphericFeedbackCount = #definition.atmosphericFeedback,
		atmosphericFeedbackDefinitions = Serialization.deepCopy(definition.atmosphericFeedback),
		environmentalReactionCount = #definition.environmentalReactions,
		environmentalReactionDefinitions = Serialization.deepCopy(
			definition.environmentalReactions
		),
		completionInteractionIds = Serialization.deepCopy(definition.completionInteractionIds),
		resetCount = snapshot.resetCount,
		playerProgress = snapshot.playerProgress,
		events = snapshot.events,
		validationFailureCount = #snapshot.validationFailures,
	}
end

return Snapshots

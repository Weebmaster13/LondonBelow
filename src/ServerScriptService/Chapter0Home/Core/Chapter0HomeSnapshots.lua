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
		completionInteractionIds = Serialization.deepCopy(definition.completionInteractionIds),
		resetCount = snapshot.resetCount,
		playerProgress = snapshot.playerProgress,
		events = snapshot.events,
		validationFailureCount = #snapshot.validationFailures,
	}
end

return Snapshots

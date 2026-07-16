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
		environmentalReactionAttributeNames = Serialization.deepCopy(
			Types.EnvironmentalReactionAttributeNames
		),
		environmentalReactionAttributePrefix = Types.EnvironmentalReactionAttributePrefix,
		atmosphericProgressionStageCount = #definition.atmosphericProgressionStages,
		atmosphericProgressionTransitionCount = #definition.atmosphericProgressionTransitions,
		atmosphericProgressionStages = Serialization.deepCopy(
			definition.atmosphericProgressionStages
		),
		atmosphericProgressionTransitions = Serialization.deepCopy(
			definition.atmosphericProgressionTransitions
		),
		atmosphericProgressionLimits = {
			maxStages = Types.Limits.MaxAtmosphericProgressionStages,
			maxTransitions = Types.Limits.MaxAtmosphericProgressionTransitions,
			maxMetadataKeys = Types.Limits.MaxAtmosphericProgressionMetadataKeys,
			maxHistoryPerPlayer = Types.Limits.MaxAtmosphericProgressionHistoryPerPlayer,
			maxOptionalModifiers = Types.Limits.MaxAtmosphericProgressionOptionalModifiers,
			maxTransitionRequirements = Types.Limits.MaxAtmosphericProgressionTransitionRequirements,
		},
		atmosphericProgressionPosture = {
			serverAuthoritative = true,
			deterministicOrdering = true,
			canonicalStages = true,
			canonicalTransitions = true,
			boundedHistory = true,
			perPlayerIsolated = true,
			resetDeterministic = true,
			optionalInteractionsNonBlocking = true,
		},
		completionInteractionIds = Serialization.deepCopy(definition.completionInteractionIds),
		resetCount = snapshot.resetCount,
		playerProgress = snapshot.playerProgress,
		events = snapshot.events,
		validationFailureCount = #snapshot.validationFailures,
	}
end

return Snapshots

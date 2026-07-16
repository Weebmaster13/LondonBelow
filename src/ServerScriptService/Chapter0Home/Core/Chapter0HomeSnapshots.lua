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
		atmosphericProgressionStageIds = Serialization.deepCopy(
			Types.CanonicalAtmosphericProgressionStageIds
		),
		atmosphericProgressionTransitionIds = Serialization.deepCopy(
			Types.CanonicalAtmosphericProgressionTransitionIds
		),
		atmosphericProgressionInitialStageId = Types.InitialAtmosphericProgressionStageId,
		atmosphericProgressionStages = Serialization.deepCopy(
			definition.atmosphericProgressionStages
		),
		atmosphericProgressionTransitions = Serialization.deepCopy(
			definition.atmosphericProgressionTransitions
		),
		atmosphericProgressionTransitionReferenceSchema = Serialization.deepCopy(
			Types.CanonicalAtmosphericProgressionTransitionDefinitions
		),
		atmosphericProgressionPostureKeys = Serialization.deepCopy(
			Types.AtmosphericProgressionPostureKeys
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
			exactStageDefinitions = true,
			exactTransitionDefinitions = true,
			exactInitialStage = true,
			exactReferenceBindings = true,
			transitionSequenceValidated = true,
			optionalModifierNonBlocking = true,
			repeatedTransitionsIdempotent = true,
			failedValidationNoMutation = true,
			boundedHistory = true,
			deterministicHistoryEviction = true,
			perPlayerIsolated = true,
			resetDeterministic = true,
			shutdownOwnedCleanup = true,
			existingFeedbackReused = true,
			existingReactionsReused = true,
			noNewRemotes = true,
			noPersistence = true,
			noAnalytics = true,
			noTelemetry = true,
			noMonsterAI = true,
			noChapter1Content = true,
		},
		observationFactCount = #definition.observationFacts,
		observationFactIds = Serialization.deepCopy(Types.CanonicalObservationFactIds),
		observationRuntimeIds = Serialization.deepCopy(Types.CanonicalObservationRuntimeIds),
		observationContractVersion = Types.ObservationContractVersion,
		observationSourceRuntime = Types.ObservationSourceRuntime,
		observationAuthority = Types.ObservationAuthority,
		observationKinds = Serialization.deepCopy(Types.ObservationKind),
		observationDefinitions = Serialization.deepCopy(definition.observationFacts),
		observationSourceReferenceSchema = Serialization.deepCopy(
			Types.ObservationSourceReferenceSchema
		),
		observationLimits = {
			maxDefinitions = Types.Limits.MaxObservationDefinitions,
			maxHistoryPerPlayer = Types.Limits.MaxObservationHistoryPerPlayer,
			maxMetadataKeys = Types.Limits.MaxObservationMetadataKeys,
			maxPayloadDepth = Types.Limits.MaxObservationPayloadDepth,
			maxPayloadEntries = Types.Limits.MaxObservationPayloadEntries,
			maxSequenceValue = Types.Limits.MaxObservationSequenceValue,
			maxOptionalModifiers = Types.Limits.MaxOptionalObservationModifiers,
		},
		observationPostureKeys = Serialization.deepCopy(Types.ObservationPostureKeys),
		observationSnapshotSchemaNames = Serialization.deepCopy(
			Types.ObservationSnapshotSchemaNames
		),
		chapter0HomeObservationPosture = {
			serverAuthoritative = true,
			chapterStateReadOnly = true,
			observationRuntimeReused = true,
			exactFactDefinitions = true,
			exactFactOrdering = true,
			exactSourceChapter = true,
			exactSourceRuntime = true,
			exactContractVersion = true,
			exactAuthorityMarker = true,
			exactReferenceBindings = true,
			deterministicSequence = true,
			deterministicDeduplication = true,
			repeatedEmissionIdempotent = true,
			failedValidationNoMutation = true,
			boundedHistory = true,
			deterministicHistoryEviction = true,
			optionalModifiersNonBlocking = true,
			perPlayerIsolated = true,
			resetDeterministic = true,
			shutdownOwnedCleanup = true,
			publicationBoundaryExact = true,
			noDuplicatePublication = true,
			noNewRemotes = true,
			noPersistence = true,
			noAnalytics = true,
			noTelemetry = true,
			noMonsterAI = true,
			noChapter1Content = true,
		},
		completionInteractionIds = Serialization.deepCopy(definition.completionInteractionIds),
		resetCount = snapshot.resetCount,
		playerProgress = snapshot.playerProgress,
		events = snapshot.events,
		validationFailureCount = #snapshot.validationFailures,
	}
end

return Snapshots

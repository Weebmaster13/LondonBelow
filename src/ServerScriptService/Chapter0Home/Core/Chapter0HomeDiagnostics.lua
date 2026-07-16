--!strict

local Types = require(script.Parent.Chapter0HomeTypes)

local Diagnostics = {}

function Diagnostics.capture(lifecycle: any, definition: Types.ChapterDefinition, state: any)
	local snapshot = state.snapshot()

	return {
		provider = Types.ProviderName,
		initialized = lifecycle.initialized,
		started = lifecycle.started,
		chapterId = definition.chapterId,
		chapter0HomePosture = {
			serverAuthoritative = true,
			usesExistingInteractionRuntime = true,
			usesExistingFeedbackDelivery = true,
			addsNewRemotes = false,
			writesDataStore = false,
			usesAnalytics = false,
			workspaceMutationScoped = true,
			deterministicReset = true,
		},
		atmosphericFeedbackPosture = {
			serverApproved = true,
			perPlayerIsolated = true,
			boundedHistory = true,
			usesExistingPlayerExperienceFeedback = true,
			addsNewRemotes = false,
			writesDataStore = false,
			usesAnalytics = false,
			usesTelemetry = false,
			addsMonsterAi = false,
			addsChapterOneContent = false,
		},
		environmentalReactionPosture = {
			serverAuthoritative = true,
			deterministicOrdering = true,
			exactReactionDefinitions = true,
			reactionTargetValidation = true,
			scalarAttributeProjection = true,
			workspaceMutationScoped = true,
			perPlayerIsolated = true,
			boundedHistory = true,
			addsNewRuntime = false,
			addsNewRemotes = false,
			writesDataStore = false,
			usesAnalytics = false,
			usesTelemetry = false,
			addsMonsterAi = false,
			addsChapterOneContent = false,
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
		counts = {
			rooms = #definition.rooms,
			interactions = #definition.interactions,
			atmosphericFeedback = #definition.atmosphericFeedback,
			environmentalReactions = #definition.environmentalReactions,
			environmentalReactionAttributes = 7,
			atmosphericProgressionStages = #definition.atmosphericProgressionStages,
			atmosphericProgressionTransitions = #definition.atmosphericProgressionTransitions,
			observationFacts = #definition.observationFacts,
			events = #snapshot.events,
			validationFailures = #snapshot.validationFailures,
			worldConnections = lifecycle.worldConnectionCount,
			lifecycleConnections = lifecycle.lifecycleConnectionCount,
			ownedRoots = lifecycle.ownedRootCount,
			foreignRoots = lifecycle.foreignRootCount,
		},
		status = snapshot.status,
		lastSelfChecks = lifecycle.lastSelfChecks,
	}
end

function Diagnostics.validate(dependencies: any): (boolean, string?)
	if type(dependencies.Validation) ~= "table" then
		return false, "Validation dependency missing"
	end

	if type(dependencies.State) ~= "table" then
		return false, "State dependency missing"
	end

	return true, nil
end

return Diagnostics

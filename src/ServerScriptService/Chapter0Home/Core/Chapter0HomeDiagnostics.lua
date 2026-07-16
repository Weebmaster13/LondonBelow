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
		counts = {
			rooms = #definition.rooms,
			interactions = #definition.interactions,
			atmosphericFeedback = #definition.atmosphericFeedback,
			environmentalReactions = #definition.environmentalReactions,
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

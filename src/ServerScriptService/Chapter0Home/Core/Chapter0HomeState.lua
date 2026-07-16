--!strict

local Types = require(script.Parent.Chapter0HomeTypes)
local Serialization = require(script.Parent.Chapter0HomeSerialization)

local State = {}

local runtimeStatus = Types.PhaseStatus.NotStarted
local playerProgress: { [number]: Types.PlayerProgress } = {}
local events: { any } = {}
local validationFailures: { any } = {}
local resetCount = 0

local function trimEvents()
	while #events > Types.Limits.MaxEvents do
		table.remove(events, 1)
	end
end

local function trimValidationFailures()
	while #validationFailures > Types.Limits.MaxValidationFailures do
		table.remove(validationFailures, 1)
	end
end

local function playerProgressCount(): number
	local count = 0

	for _ in pairs(playerProgress) do
		count += 1
	end

	return count
end

local function progressFor(userId: number): Types.PlayerProgress?
	local progress = playerProgress[userId]

	if progress == nil then
		if playerProgressCount() >= Types.Limits.MaxPlayerStates then
			return nil
		end

		progress = {
			userId = userId,
			status = Types.PhaseStatus.Started,
			interactions = {},
			feedbackHistory = {},
			reactionHistory = {},
			progressionStageId = Types.InitialAtmosphericProgressionStageId,
			progressionTransitions = {},
			progressionHistory = {},
			optionalAtmosphericModifiers = {},
			emittedObservationFactIds = {},
			observationHistory = {},
			observationSequence = 0,
			optionalObservationModifiers = {},
			completedAt = nil,
		}
		playerProgress[userId] = progress
	end

	return progress
end

local function canonicalTransitionFor(transitionId: string): any?
	for _, transitionDefinition in
		ipairs(Types.CanonicalAtmosphericProgressionTransitionDefinitions)
	do
		if transitionDefinition.transitionId == transitionId then
			return transitionDefinition
		end
	end

	return nil
end

local function requiredInteractionsMatch(actual: any, expected: { string }): boolean
	if type(actual) ~= "table" or #actual ~= #expected then
		return false
	end

	for index, expectedId in ipairs(expected) do
		if actual[index] ~= expectedId then
			return false
		end
	end

	return true
end

local function transitionPayloadMatchesCanonical(transition: any, canonical: any): boolean
	return transition.interactionId == canonical.interactionId
		and transition.fromStageId == canonical.fromStageId
		and transition.toStageId == canonical.toStageId
		and transition.order == canonical.order
		and transition.feedbackId == canonical.feedbackId
		and transition.reactionId == canonical.reactionId
		and transition.optionalModifier == canonical.optionalModifier
		and transition.completionRelevant == canonical.completionRelevant
		and transition.intensity == canonical.intensity
		and requiredInteractionsMatch(
			transition.requiredInteractionIds,
			canonical.requiredInteractionIds
		)
end

local function canonicalObservationFactFor(factId: string): any?
	for _, factDefinition in ipairs(Types.CanonicalObservationFactDefinitions) do
		if factDefinition.factId == factId then
			return factDefinition
		end
	end

	return nil
end

local function metadataMatches(actual: any, expected: any): boolean
	if type(actual) ~= "table" or type(expected) ~= "table" then
		return false
	end

	local actualCount = 0
	local expectedCount = 0

	for key, expectedValue in pairs(expected) do
		expectedCount += 1

		if actual[key] ~= expectedValue then
			return false
		end
	end

	for _ in pairs(actual) do
		actualCount += 1
	end

	return actualCount == expectedCount
end

local function observationPayloadMatchesCanonical(fact: any, canonical: any): boolean
	return fact.observationId == canonical.observationId
		and fact.chapterId == canonical.chapterId
		and fact.sourceRuntime == canonical.sourceRuntime
		and fact.contractVersion == canonical.contractVersion
		and fact.authority == canonical.authority
		and fact.kind == canonical.kind
		and fact.interactionId == canonical.interactionId
		and fact.stageId == canonical.stageId
		and fact.feedbackId == canonical.feedbackId
		and fact.reactionId == canonical.reactionId
		and fact.order == canonical.order
		and fact.intensity == canonical.intensity
		and fact.completionRelevant == canonical.completionRelevant
		and fact.optionalModifier == canonical.optionalModifier
		and metadataMatches(fact.metadata, canonical.metadata)
end

function State.setStatus(status: string)
	runtimeStatus = status
end

function State.getStatus(): string
	return runtimeStatus
end

function State.recordEvent(event: any)
	table.insert(events, Serialization.deepCopy(event))
	trimEvents()
end

function State.recordValidationFailure(reason: string, payload: any?)
	table.insert(validationFailures, {
		reason = reason,
		payload = Serialization.deepCopy(payload),
	})
	trimValidationFailures()
end

function State.recordInteraction(userId: number, interactionId: string, requiredIds: { string })
	local progress = progressFor(userId)

	if progress == nil then
		State.recordEvent({
			kind = "playerProgressLimitRejected",
			userId = userId,
			interactionId = interactionId,
			completed = false,
		})

		return false
	end

	progress.interactions[interactionId] = true

	local complete = true

	for _, requiredId in ipairs(requiredIds) do
		if progress.interactions[requiredId] ~= true then
			complete = false
			break
		end
	end

	if complete and progress.status ~= Types.PhaseStatus.Completed then
		progress.status = Types.PhaseStatus.Completed
		progress.completedAt = os.clock()
	end

	State.recordEvent({
		kind = "interaction",
		userId = userId,
		interactionId = interactionId,
		completed = complete,
	})

	return progress.status == Types.PhaseStatus.Completed
end

function State.recordAtmosphericFeedback(userId: number, feedback: any): boolean
	local progress = progressFor(userId)

	if progress == nil then
		State.recordEvent({
			kind = "feedbackProgressLimitRejected",
			userId = userId,
			feedbackId = if type(feedback) == "table" then feedback.feedbackId else nil,
		})

		return false
	end

	table.insert(progress.feedbackHistory, Serialization.deepCopy(feedback))

	while #progress.feedbackHistory > Types.Limits.MaxFeedbackHistoryPerPlayer do
		table.remove(progress.feedbackHistory, 1)
	end

	State.recordEvent({
		kind = "atmosphericFeedback",
		userId = userId,
		feedbackId = if type(feedback) == "table" then feedback.feedbackId else nil,
		interactionId = if type(feedback) == "table" then feedback.interactionId else nil,
	})

	return true
end

function State.recordEnvironmentalReaction(userId: number, reaction: any): boolean
	local progress = progressFor(userId)

	if progress == nil then
		State.recordEvent({
			kind = "reactionProgressLimitRejected",
			userId = userId,
			reactionId = if type(reaction) == "table" then reaction.reactionId else nil,
		})

		return false
	end

	table.insert(progress.reactionHistory, Serialization.deepCopy(reaction))

	while #progress.reactionHistory > Types.Limits.MaxEnvironmentalReactionHistoryPerPlayer do
		table.remove(progress.reactionHistory, 1)
	end

	State.recordEvent({
		kind = "environmentalReaction",
		userId = userId,
		reactionId = if type(reaction) == "table" then reaction.reactionId else nil,
		interactionId = if type(reaction) == "table" then reaction.interactionId else nil,
	})

	return true
end

function State.recordAtmosphericProgression(userId: number, transition: any): boolean
	if type(transition) ~= "table" or type(transition.transitionId) ~= "string" then
		return false
	end

	local canonicalTransition = canonicalTransitionFor(transition.transitionId)

	if
		canonicalTransition == nil
		or not transitionPayloadMatchesCanonical(transition, canonicalTransition)
	then
		return false
	end

	if
		playerProgress[userId] == nil
		and canonicalTransition.fromStageId ~= Types.InitialAtmosphericProgressionStageId
	then
		return false
	end

	local progress = progressFor(userId)

	if progress == nil then
		State.recordEvent({
			kind = "progressionProgressLimitRejected",
			userId = userId,
			transitionId = transition.transitionId,
		})

		return false
	end

	if progress.progressionTransitions[transition.transitionId] == true then
		return true
	end

	if progress.progressionStageId ~= canonicalTransition.fromStageId then
		return false
	end

	local copiedTransition = Serialization.deepCopy(transition)
	progress.progressionTransitions[transition.transitionId] = true

	if copiedTransition.optionalModifier == true then
		table.insert(progress.optionalAtmosphericModifiers, copiedTransition)

		while
			#progress.optionalAtmosphericModifiers
			> Types.Limits.MaxAtmosphericProgressionOptionalModifiers
		do
			table.remove(progress.optionalAtmosphericModifiers, 1)
		end
	elseif type(copiedTransition.toStageId) == "string" then
		progress.progressionStageId = copiedTransition.toStageId
	end

	table.insert(progress.progressionHistory, copiedTransition)

	while #progress.progressionHistory > Types.Limits.MaxAtmosphericProgressionHistoryPerPlayer do
		table.remove(progress.progressionHistory, 1)
	end

	State.recordEvent({
		kind = "atmosphericProgression",
		userId = userId,
		transitionId = copiedTransition.transitionId,
		stageId = progress.progressionStageId,
		optionalModifier = copiedTransition.optionalModifier == true,
	})

	return true
end

function State.recordObservationFact(userId: number, fact: any): boolean
	if type(fact) ~= "table" or type(fact.factId) ~= "string" then
		return false
	end

	local canonicalFact = canonicalObservationFactFor(fact.factId)

	if canonicalFact == nil or not observationPayloadMatchesCanonical(fact, canonicalFact) then
		return false
	end

	local progress = progressFor(userId)

	if progress == nil then
		State.recordEvent({
			kind = "observationProgressLimitRejected",
			userId = userId,
			factId = fact.factId,
		})

		return false
	end

	if progress.interactions[canonicalFact.interactionId] ~= true then
		return false
	end

	if progress.progressionStageId ~= canonicalFact.stageId then
		return false
	end

	if progress.emittedObservationFactIds[fact.factId] == true then
		return false
	end

	if progress.observationSequence + 1 > Types.Limits.MaxObservationSequenceValue then
		return false
	end

	progress.observationSequence += 1

	local copiedFact = Serialization.deepCopy(fact)
	copiedFact.sequence = progress.observationSequence
	copiedFact.sourceProgressionStageId = progress.progressionStageId

	progress.emittedObservationFactIds[fact.factId] = true
	table.insert(progress.observationHistory, copiedFact)

	while #progress.observationHistory > Types.Limits.MaxObservationHistoryPerPlayer do
		table.remove(progress.observationHistory, 1)
	end

	if copiedFact.optionalModifier == true then
		table.insert(progress.optionalObservationModifiers, copiedFact)

		while
			#progress.optionalObservationModifiers > Types.Limits.MaxOptionalObservationModifiers
		do
			table.remove(progress.optionalObservationModifiers, 1)
		end
	end

	State.recordEvent({
		kind = "chapter0HomeObservationFact",
		userId = userId,
		factId = copiedFact.factId,
		observationId = copiedFact.observationId,
		sequence = copiedFact.sequence,
	})

	return true
end

function State.removePlayer(userId: number)
	playerProgress[userId] = nil
end

function State.snapshot()
	return {
		status = runtimeStatus,
		resetCount = resetCount,
		playerProgress = Serialization.deepCopy(playerProgress),
		events = Serialization.deepCopy(events),
		validationFailures = Serialization.deepCopy(validationFailures),
	}
end

function State.clear()
	runtimeStatus = Types.PhaseStatus.Reset
	resetCount += 1
	table.clear(playerProgress)
	table.clear(events)
	table.clear(validationFailures)
end

return State

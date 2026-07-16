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
			completedAt = nil,
		}
		playerProgress[userId] = progress
	end

	return progress
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
	local progress = progressFor(userId)

	if progress == nil then
		State.recordEvent({
			kind = "progressionProgressLimitRejected",
			userId = userId,
			transitionId = if type(transition) == "table" then transition.transitionId else nil,
		})

		return false
	end

	if type(transition) ~= "table" or type(transition.transitionId) ~= "string" then
		return false
	end

	if progress.progressionTransitions[transition.transitionId] == true then
		return true
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

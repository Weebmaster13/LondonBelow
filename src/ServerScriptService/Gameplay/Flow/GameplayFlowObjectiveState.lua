--!strict

local Evidence = require(script.Parent.GameplayFlowEvidence)
local Serialization = require(script.Parent.GameplayFlowSerialization)
local Types = require(script.Parent.GameplayFlowTypes)
local Validation = require(script.Parent.GameplayFlowValidation)

local State = {}

local objectiveStates: { [string]: string } = {}
local events: { any } = {}
local transitions: { any } = {}
local evaluationQueue: { string } = {}
local conditionEvaluations = 0
local evaluationCount = 0
local revision = 0
local activeObjective: string? = nil
local checkpointEligible = false
local checkpointObjectiveId: string? = nil
local validationFailures: { any } = {}

local function rememberFailure(reason: string, payload: any?)
	table.insert(validationFailures, {
		reason = reason,
		payload = Serialization.deepCopy(payload),
	})
	if #validationFailures > Types.Limits.MaxValidationFailures then
		table.remove(validationFailures, 1)
	end
end

local function transition(objectiveId: string, fromState: string?, toState: string, reason: string)
	revision += 1
	objectiveStates[objectiveId] = toState
	if toState == Types.ObjectiveState.Active then
		activeObjective = objectiveId
	end
	local record = {
		objectiveId = objectiveId,
		fromState = fromState,
		toState = toState,
		reason = reason,
		revision = revision,
	}
	table.insert(transitions, record)
	if #transitions > Types.Limits.MaxTransitions then
		table.remove(transitions, 1)
	end
	Evidence.record("Objective" .. toState, record)
	return Serialization.deepCopy(record)
end

function State.initializeObjectives(objectiveIds: { string })
	for _, objectiveId in ipairs(objectiveIds) do
		objectiveStates[objectiveId] = Types.ObjectiveState.Locked
	end
end

function State.recordEvent(event: any): (boolean, string?)
	local ok, reason = Validation.event(event)
	if not ok then
		rememberFailure(reason or "event rejected", event)
		return false, reason
	end
	table.insert(events, Serialization.freezeCopy(event))
	if #events > Types.Limits.MaxEvents then
		table.remove(events, 1)
	end
	Evidence.record("RuntimeEvent", event)
	return true, nil
end

function State.enqueueEvaluation(reason: string)
	table.insert(evaluationQueue, reason)
	if #evaluationQueue > Types.Limits.MaxEvaluationQueue then
		table.remove(evaluationQueue, 1)
	end
end

function State.markAvailable(objectiveId: string, reason: string)
	return transition(
		objectiveId,
		objectiveStates[objectiveId],
		Types.ObjectiveState.Available,
		reason
	)
end

function State.activate(objectiveId: string, reason: string)
	local currentActive = activeObjective
	if currentActive ~= nil and objectiveStates[currentActive] == Types.ObjectiveState.Active then
		return nil
	end
	return transition(
		objectiveId,
		objectiveStates[objectiveId],
		Types.ObjectiveState.Active,
		reason
	)
end

function State.complete(objectiveId: string, reason: string)
	if activeObjective == objectiveId then
		activeObjective = nil
	end
	return transition(
		objectiveId,
		objectiveStates[objectiveId],
		Types.ObjectiveState.Completed,
		reason
	)
end

function State.fail(objectiveId: string, reason: string)
	if activeObjective == objectiveId then
		activeObjective = nil
	end
	return transition(
		objectiveId,
		objectiveStates[objectiveId],
		Types.ObjectiveState.Failed,
		reason
	)
end

function State.skip(objectiveId: string, reason: string)
	if activeObjective == objectiveId then
		activeObjective = nil
	end
	return transition(
		objectiveId,
		objectiveStates[objectiveId],
		Types.ObjectiveState.Skipped,
		reason
	)
end

function State.setCheckpointEligible(objectiveId: string)
	checkpointEligible = true
	checkpointObjectiveId = objectiveId
	Evidence.record("CheckpointEligibility", { objectiveId = objectiveId })
end

function State.bumpEvaluation(conditionCount: number)
	evaluationCount += 1
	conditionEvaluations += conditionCount
end

function State.getObjectiveState(objectiveId: string): string?
	return objectiveStates[objectiveId]
end

function State.getStates()
	return Serialization.deepCopy(objectiveStates)
end

function State.getEvents()
	return Serialization.deepCopy(events)
end

function State.getActiveObjective(): string?
	return activeObjective
end

function State.inspect()
	local completed = {}
	local failed = {}
	local skipped = {}
	for objectiveId, stateName in pairs(objectiveStates) do
		if stateName == Types.ObjectiveState.Completed then
			table.insert(completed, objectiveId)
		elseif stateName == Types.ObjectiveState.Failed then
			table.insert(failed, objectiveId)
		elseif stateName == Types.ObjectiveState.Skipped then
			table.insert(skipped, objectiveId)
		end
	end
	table.sort(completed)
	table.sort(failed)
	table.sort(skipped)
	return {
		activeObjective = activeObjective,
		completedObjectives = completed,
		failedObjectives = failed,
		skippedObjectives = skipped,
		queuedEvaluations = #evaluationQueue,
		conditionEvaluations = conditionEvaluations,
		objectiveTransitions = #transitions,
		checkpointEligible = checkpointEligible,
		checkpointObjectiveId = checkpointObjectiveId,
		evaluationCount = evaluationCount,
		transitionCount = #transitions,
		eventCount = #events,
		revision = revision,
		validationFailures = Serialization.deepCopy(validationFailures),
	}
end

function State.serialize()
	return {
		objectiveStates = Serialization.deepCopy(objectiveStates),
		events = Serialization.deepCopy(events),
		transitions = Serialization.deepCopy(transitions),
		activeObjective = activeObjective,
		checkpointEligible = checkpointEligible,
		checkpointObjectiveId = checkpointObjectiveId,
		evaluationCount = evaluationCount,
		conditionEvaluations = conditionEvaluations,
		revision = revision,
	}
end

function State.clear()
	table.clear(objectiveStates)
	table.clear(events)
	table.clear(transitions)
	table.clear(evaluationQueue)
	table.clear(validationFailures)
	Evidence.clear()
	conditionEvaluations = 0
	evaluationCount = 0
	revision = 0
	activeObjective = nil
	checkpointEligible = false
	checkpointObjectiveId = nil
end

return State

--!strict

local Definitions = require(script.Parent.GameplayFlowDefinitions)
local Evaluation = require(script.Parent.GameplayFlowObjectiveEvaluation)
local Registry = require(script.Parent.GameplayFlowObjectiveRegistry)
local State = require(script.Parent.GameplayFlowObjectiveState)
local Types = require(script.Parent.GameplayFlowTypes)
local Validation = require(script.Parent.GameplayFlowValidation)

local SelfChecks = {}

local function add(checks: { any }, name: string, ok: boolean, message: string?)
	table.insert(checks, {
		name = name,
		ok = ok,
		message = message or "",
	})
end

local function summarize(checks: { any })
	local failures = {}
	for _, check in ipairs(checks) do
		if not check.ok then
			table.insert(failures, check)
		end
	end
	return {
		ok = #failures == 0,
		total = #checks,
		passed = #checks - #failures,
		failed = #failures,
		failures = failures,
	}
end

local function reset()
	Registry.clear()
	State.clear()
end

local function registerChapter0(): (boolean, string?)
	local objectives = Definitions.getChapter0Objectives()
	local ok, reason = Registry.registerAll(objectives)
	if not ok then
		return false, reason
	end
	local order = Registry.order()
	State.initializeObjectives(order)
	Evaluation.evaluate(Registry, State, "self-check initialization")
	return true, nil
end

function SelfChecks.run()
	local checks = {}

	reset()
	local ok, reason = registerChapter0()
	add(checks, "objective registry accepts Chapter 0 graph", ok, reason)
	add(
		checks,
		"deterministic first objective activates",
		State.getActiveObjective() == "chapter0.objective.inspectMumsNote"
	)

	local graphOk = Validation.graph(Definitions.getChapter0Objectives())
	add(checks, "objective graph validation passes", graphOk)

	local duplicateGraph = Definitions.getChapter0Objectives()
	table.insert(duplicateGraph, duplicateGraph[1])
	local duplicateOk = Validation.graph(duplicateGraph)
	add(checks, "duplicate objective rejects", duplicateOk == false)

	local missingGraph = Definitions.getChapter0Objectives()
	missingGraph[2].prerequisites.objectiveIds = { "missing.objective" }
	local missingOk = Validation.graph(missingGraph)
	add(checks, "missing prerequisite rejects", missingOk == false)

	local cycleGraph = Definitions.getChapter0Objectives()
	cycleGraph[1].prerequisites.objectiveIds = { "chapter0.objective.leaveHome" }
	cycleGraph[4].nextObjectives = { "chapter0.objective.inspectMumsNote" }
	local cycleOk = Validation.graph(cycleGraph)
	add(checks, "cycle detection rejects graph", cycleOk == false)

	local invalidCondition = {
		conditionId = "bad.condition",
		conditionKind = "Unsupported",
	}
	local conditionOk = Validation.condition(invalidCondition)
	add(checks, "unsupported condition kind rejects", conditionOk == false)

	local beforeInvalid = State.inspect().eventCount
	local eventOk = State.recordEvent({ eventKind = "missingId" })
	local afterInvalid = State.inspect().eventCount
	add(
		checks,
		"failed validation does not mutate event state",
		eventOk == false and beforeInvalid == afterInvalid
	)

	State.recordEvent({
		eventId = "selfcheck.event.note",
		eventKind = Types.ConditionKind.InspectionCompleted,
		referenceId = "chapter0.home.sittingRoom.mumsNote",
	})
	Evaluation.evaluate(Registry, State, "note inspected")
	add(
		checks,
		"inspection completes first objective",
		State.getObjectiveState("chapter0.objective.inspectMumsNote")
			== Types.ObjectiveState.Completed
	)
	add(
		checks,
		"restore power activates after note",
		State.getActiveObjective() == "chapter0.objective.restorePower"
	)

	State.recordEvent({
		eventId = "selfcheck.event.breaker",
		eventKind = Types.ConditionKind.BinaryMechanismState,
		objectId = "chapter0.home.kitchen.breaker",
		state = "ON",
	})
	Evaluation.evaluate(Registry, State, "breaker enabled")
	add(
		checks,
		"breaker condition completes power objective",
		State.getObjectiveState("chapter0.objective.restorePower") == Types.ObjectiveState.Completed
	)
	add(
		checks,
		"front door activates after power",
		State.getActiveObjective() == "chapter0.objective.openFrontDoor"
	)

	State.recordEvent({
		eventId = "selfcheck.event.frontDoor",
		eventKind = Types.ConditionKind.EnvironmentalState,
		objectId = "chapter0.home.entry.frontDoor",
		state = "OPEN",
	})
	Evaluation.evaluate(Registry, State, "front door opened")
	add(
		checks,
		"front door objective completes",
		State.getObjectiveState("chapter0.objective.openFrontDoor")
			== Types.ObjectiveState.Completed
	)
	add(
		checks,
		"leave home activates after front door",
		State.getActiveObjective() == "chapter0.objective.leaveHome"
	)
	add(
		checks,
		"checkpoint eligibility unlocks on leave home",
		State.inspect().checkpointEligible == true
	)

	State.recordEvent({
		eventId = "chapter0.home.leaveHomeReached",
		eventKind = Types.ConditionKind.RuntimeEvent,
	})
	Evaluation.evaluate(Registry, State, "leave home reached")
	add(
		checks,
		"leave home completion works",
		State.getObjectiveState("chapter0.objective.leaveHome") == Types.ObjectiveState.Completed
	)

	local inspection = State.inspect()
	add(
		checks,
		"diagnostic counters record evaluations",
		inspection.evaluationCount >= 5 and inspection.conditionEvaluations > 0
	)
	add(checks, "evidence records objective flow", inspection.transitionCount >= 7)

	local beforeClear = State.inspect().eventCount
	reset()
	add(
		checks,
		"shutdown cleanup clears state",
		beforeClear > 0 and State.inspect().eventCount == 0 and Registry.count() == 0
	)

	return summarize(checks)
end

return SelfChecks

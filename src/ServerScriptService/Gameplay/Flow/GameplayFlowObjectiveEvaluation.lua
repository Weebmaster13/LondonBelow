--!strict

local Conditions = require(script.Parent.GameplayFlowObjectiveConditions)
local Evidence = require(script.Parent.GameplayFlowEvidence)
local Types = require(script.Parent.GameplayFlowTypes)

local Evaluation = {}

local function countConditions(objective: any): number
	return #objective.completionConditions + #objective.failureConditions
end

function Evaluation.evaluate(registry: any, state: any, reason: string?)
	local objectiveOrder = registry.order()
	local states = state.getStates()
	local events = state.getEvents()
	local transitions = {}
	local activeObjective = state.getActiveObjective()
	local conditionCount = 0

	for _, objectiveId in ipairs(objectiveOrder) do
		local objective = registry.getFrozen(objectiveId)
		conditionCount += countConditions(objective)
		local currentState = states[objectiveId]
		if currentState == Types.ObjectiveState.Locked then
			if Conditions.prerequisitesSatisfied(objective, states) then
				table.insert(
					transitions,
					state.markAvailable(objectiveId, reason or "prerequisites satisfied")
				)
				states[objectiveId] = Types.ObjectiveState.Available
			end
		end
	end

	for _, objectiveId in ipairs(objectiveOrder) do
		if activeObjective == nil and states[objectiveId] == Types.ObjectiveState.Available then
			local objective = registry.getFrozen(objectiveId)
			if Conditions.prerequisitesSatisfied(objective, states) then
				table.insert(
					transitions,
					state.activate(objectiveId, reason or "objective available")
				)
				activeObjective = objectiveId
				states[objectiveId] = Types.ObjectiveState.Active
			end
		end
	end

	local active = state.getActiveObjective()
	if active ~= nil then
		local objective = registry.getFrozen(active)
		if
			#objective.failureConditions > 0
			and Conditions.allSatisfied(objective.failureConditions, events, states)
		then
			table.insert(transitions, state.fail(active, reason or "failure conditions satisfied"))
			active = nil
		elseif Conditions.allSatisfied(objective.completionConditions, events, states) then
			table.insert(
				transitions,
				state.complete(active, reason or "completion conditions satisfied")
			)
			states[active] = Types.ObjectiveState.Completed
			for _, nextObjectiveId in ipairs(objective.nextObjectives) do
				local nextObjective = registry.getFrozen(nextObjectiveId)
				if Conditions.prerequisitesSatisfied(nextObjective, states) then
					if state.getObjectiveState(nextObjectiveId) == Types.ObjectiveState.Locked then
						table.insert(
							transitions,
							state.markAvailable(nextObjectiveId, "next objective unlocked")
						)
					end
				end
			end
			active = nil
		end
	end

	if active == nil then
		for _, objectiveId in ipairs(objectiveOrder) do
			local objective = registry.getFrozen(objectiveId)
			local currentState = state.getObjectiveState(objectiveId)
			if currentState == Types.ObjectiveState.Available then
				table.insert(
					transitions,
					state.activate(objectiveId, "deterministic next objective")
				)
				if objective.checkpointEligible then
					state.setCheckpointEligible(objectiveId)
				end
				break
			elseif currentState == Types.ObjectiveState.Active and objective.checkpointEligible then
				state.setCheckpointEligible(objectiveId)
				break
			end
		end
	end

	state.bumpEvaluation(conditionCount)
	Evidence.record("ObjectiveEvaluation", {
		reason = reason or "manual evaluation",
		transitionCount = #transitions,
		conditionCount = conditionCount,
		activeObjective = state.getActiveObjective(),
	})

	return {
		ok = true,
		transitionCount = #transitions,
		transitions = transitions,
		activeObjective = state.getActiveObjective(),
	}
end

return Evaluation

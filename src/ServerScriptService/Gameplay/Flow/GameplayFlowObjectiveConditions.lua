--!strict

local Types = require(script.Parent.GameplayFlowTypes)

local Conditions = {}

local function findEvent(events: { any }, predicate: (any) -> boolean): any?
	for index = #events, 1, -1 do
		local event = events[index]
		if predicate(event) then
			return event
		end
	end
	return nil
end

function Conditions.prerequisitesSatisfied(objective: any, states: { [string]: string }): boolean
	local prerequisiteIds = objective.prerequisites.objectiveIds
	if #prerequisiteIds == 0 then
		return true
	end
	if objective.prerequisites.mode == Types.PrerequisiteMode.Or then
		for _, objectiveId in ipairs(prerequisiteIds) do
			if states[objectiveId] == Types.ObjectiveState.Completed then
				return true
			end
		end
		return false
	end
	if objective.prerequisites.mode ~= Types.PrerequisiteMode.And then
		return false
	end
	for _, objectiveId in ipairs(prerequisiteIds) do
		if states[objectiveId] ~= Types.ObjectiveState.Completed then
			return false
		end
	end
	return true
end

function Conditions.isSatisfied(
	condition: any,
	events: { any },
	states: { [string]: string }
): boolean
	local kind = condition.conditionKind
	if kind == Types.ConditionKind.ObjectiveCompleted then
		return states[condition.objectiveId] == Types.ObjectiveState.Completed
	end
	if kind == Types.ConditionKind.RuntimeEvent then
		return findEvent(events, function(event)
			return event.eventId == condition.eventId
		end) ~= nil
	end
	if kind == Types.ConditionKind.PresentationAcknowledged then
		return findEvent(events, function(event)
			return event.presentationId == condition.presentationId
				and event.eventKind == Types.ConditionKind.PresentationAcknowledged
		end) ~= nil
	end
	if kind == Types.ConditionKind.InteractionCompleted then
		return findEvent(events, function(event)
			return event.referenceId == condition.referenceId
				and (
					event.eventKind == Types.ConditionKind.InteractionCompleted
					or event.eventKind == "Interaction.Complete"
				)
		end) ~= nil
	end
	if kind == Types.ConditionKind.InspectionCompleted then
		return findEvent(events, function(event)
			return event.referenceId == condition.referenceId
				and (
					event.eventKind == Types.ConditionKind.InspectionCompleted
					or event.eventKind == "Interaction.ReadNote"
					or event.eventKind == "InspectableObject.Inspected"
				)
		end) ~= nil
	end
	if kind == Types.ConditionKind.EnvironmentalState then
		return findEvent(events, function(event)
			return event.objectId == condition.objectId and event.state == condition.expectedState
		end) ~= nil
	end
	if kind == Types.ConditionKind.BinaryMechanismState then
		return findEvent(events, function(event)
			return event.objectId == condition.objectId and event.state == condition.expectedState
		end) ~= nil
	end
	return false
end

function Conditions.allSatisfied(
	conditions: { any },
	events: { any },
	states: { [string]: string }
): boolean
	for _, condition in ipairs(conditions) do
		if not Conditions.isSatisfied(condition, events, states) then
			return false
		end
	end
	return true
end

return Conditions

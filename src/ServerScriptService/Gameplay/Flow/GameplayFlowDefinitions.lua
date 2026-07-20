--!strict

local Types = require(script.Parent.GameplayFlowTypes)

local Definitions = {}

local function deepCopy(value: any): any
	if type(value) ~= "table" then
		return value
	end
	local copy = {}
	for key, child in pairs(value) do
		copy[deepCopy(key)] = deepCopy(child)
	end
	return copy
end

Definitions.Chapter0Objectives = {
	{
		objectiveId = "chapter0.objective.inspectMumsNote",
		titleKey = "chapter0.objective.inspectMumsNote.title",
		descriptionKey = "chapter0.objective.inspectMumsNote.description",
		chapterId = Types.ChapterId,
		priority = 10,
		prerequisites = {
			mode = Types.PrerequisiteMode.And,
			objectiveIds = {},
		},
		completionConditions = {
			{
				conditionId = "chapter0.condition.mumsNoteInspected",
				conditionKind = Types.ConditionKind.InspectionCompleted,
				referenceId = "chapter0.home.sittingRoom.mumsNote",
			},
		},
		failureConditions = {},
		nextObjectives = { "chapter0.objective.restorePower" },
		optionalObjectives = {},
		checkpointEligible = false,
		tags = { "chapter0", "home", "inspection" },
		metadata = {
			sourceRuntime = "Interaction Runtime",
			presentationKey = "chapter0.presentation.inspectMumsNote",
		},
	},
	{
		objectiveId = "chapter0.objective.restorePower",
		titleKey = "chapter0.objective.restorePower.title",
		descriptionKey = "chapter0.objective.restorePower.description",
		chapterId = Types.ChapterId,
		priority = 20,
		prerequisites = {
			mode = Types.PrerequisiteMode.And,
			objectiveIds = { "chapter0.objective.inspectMumsNote" },
		},
		completionConditions = {
			{
				conditionId = "chapter0.condition.breakerEnabled",
				conditionKind = Types.ConditionKind.BinaryMechanismState,
				objectId = "chapter0.home.kitchen.breaker",
				expectedState = "ON",
			},
		},
		failureConditions = {},
		nextObjectives = { "chapter0.objective.openFrontDoor" },
		optionalObjectives = {},
		checkpointEligible = false,
		tags = { "chapter0", "home", "power" },
		metadata = {
			sourceRuntime = "Environmental Interaction Runtime",
			presentationKey = "chapter0.presentation.restorePower",
		},
	},
	{
		objectiveId = "chapter0.objective.openFrontDoor",
		titleKey = "chapter0.objective.openFrontDoor.title",
		descriptionKey = "chapter0.objective.openFrontDoor.description",
		chapterId = Types.ChapterId,
		priority = 30,
		prerequisites = {
			mode = Types.PrerequisiteMode.And,
			objectiveIds = { "chapter0.objective.restorePower" },
		},
		completionConditions = {
			{
				conditionId = "chapter0.condition.frontDoorOpen",
				conditionKind = Types.ConditionKind.EnvironmentalState,
				objectId = "chapter0.home.entry.frontDoor",
				expectedState = "OPEN",
			},
		},
		failureConditions = {},
		nextObjectives = { "chapter0.objective.leaveHome" },
		optionalObjectives = {},
		checkpointEligible = false,
		tags = { "chapter0", "home", "door" },
		metadata = {
			sourceRuntime = "Environmental Interaction Runtime",
			presentationKey = "chapter0.presentation.openFrontDoor",
		},
	},
	{
		objectiveId = "chapter0.objective.leaveHome",
		titleKey = "chapter0.objective.leaveHome.title",
		descriptionKey = "chapter0.objective.leaveHome.description",
		chapterId = Types.ChapterId,
		priority = 40,
		prerequisites = {
			mode = Types.PrerequisiteMode.And,
			objectiveIds = { "chapter0.objective.openFrontDoor" },
		},
		completionConditions = {
			{
				conditionId = "chapter0.condition.leaveHomeReached",
				conditionKind = Types.ConditionKind.RuntimeEvent,
				eventId = "chapter0.home.leaveHomeReached",
			},
		},
		failureConditions = {},
		nextObjectives = {},
		optionalObjectives = {},
		checkpointEligible = true,
		tags = { "chapter0", "home", "checkpoint" },
		metadata = {
			sourceRuntime = "Gameplay Flow Runtime",
			presentationKey = "chapter0.presentation.leaveHome",
		},
	},
}

function Definitions.getChapter0Objectives()
	local copy = {}
	for _, objective in ipairs(Definitions.Chapter0Objectives) do
		table.insert(copy, deepCopy(objective))
	end
	return copy
end

return Definitions

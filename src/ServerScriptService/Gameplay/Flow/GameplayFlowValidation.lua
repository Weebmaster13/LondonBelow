--!strict

local Types = require(script.Parent.GameplayFlowTypes)

local Validation = {}

local allowedObjectiveStates = {
	[Types.ObjectiveState.Locked] = true,
	[Types.ObjectiveState.Available] = true,
	[Types.ObjectiveState.Active] = true,
	[Types.ObjectiveState.Completed] = true,
	[Types.ObjectiveState.Failed] = true,
	[Types.ObjectiveState.Skipped] = true,
}

local allowedConditionKinds = {
	[Types.ConditionKind.InteractionCompleted] = true,
	[Types.ConditionKind.EnvironmentalState] = true,
	[Types.ConditionKind.InspectionCompleted] = true,
	[Types.ConditionKind.BinaryMechanismState] = true,
	[Types.ConditionKind.PresentationAcknowledged] = true,
	[Types.ConditionKind.RuntimeEvent] = true,
	[Types.ConditionKind.ObjectiveCompleted] = true,
}

local allowedPrerequisiteModes = {
	[Types.PrerequisiteMode.And] = true,
	[Types.PrerequisiteMode.Or] = true,
}

local forbiddenKeys = {
	remote = true,
	remotes = true,
	clientAuthority = true,
	dataStore = true,
	http = true,
	messagingService = true,
	analytics = true,
	telemetry = true,
	workspace = true,
	workspaceMutation = true,
	inventory = true,
	dialogue = true,
	monsterAI = true,
	chapter1 = true,
	saveWrite = true,
	uiExecution = true,
}

local function isNonEmptyString(value: any): boolean
	return type(value) == "string" and value ~= "" and #value <= Types.Limits.MaxStringLength
end

local function rejectUnsafe(value: any, depth: number?): (boolean, string?)
	local activeDepth = depth or 0
	if activeDepth > 8 then
		return false, "payload exceeds maximum depth"
	end
	if type(value) ~= "table" then
		return true, nil
	end
	for key, child in pairs(value) do
		if type(key) == "string" and forbiddenKeys[key] == true then
			return false, "forbidden field: " .. key
		end
		if type(child) == "function" or type(child) == "thread" or type(child) == "userdata" then
			return false, "unsafe runtime value"
		end
		if type(child) == "string" and #child > Types.Limits.MaxStringLength then
			return false, "string exceeds maximum length"
		end
		local ok, reason = rejectUnsafe(child, activeDepth + 1)
		if not ok then
			return false, reason
		end
	end
	return true, nil
end

local function validateIdArray(values: any, maxCount: number, label: string): (boolean, string?)
	if type(values) ~= "table" then
		return false, label .. " must be an array"
	end
	if #values > maxCount then
		return false, label .. " exceeds limit"
	end
	local seen = {}
	for _, value in ipairs(values) do
		if not isNonEmptyString(value) then
			return false, label .. " contains invalid id"
		end
		if seen[value] then
			return false, label .. " contains duplicate id"
		end
		seen[value] = true
	end
	return true, nil
end

function Validation.condition(condition: any): (boolean, string?)
	if type(condition) ~= "table" then
		return false, "condition must be a table"
	end
	if not isNonEmptyString(condition.conditionId) then
		return false, "conditionId is required"
	end
	if not allowedConditionKinds[condition.conditionKind] then
		return false, "unsupported conditionKind"
	end
	local kind = condition.conditionKind
	if kind == Types.ConditionKind.RuntimeEvent and not isNonEmptyString(condition.eventId) then
		return false, "runtime event condition requires eventId"
	end
	if
		kind == Types.ConditionKind.ObjectiveCompleted
		and not isNonEmptyString(condition.objectiveId)
	then
		return false, "objective completed condition requires objectiveId"
	end
	if
		(
			kind == Types.ConditionKind.EnvironmentalState
			or kind == Types.ConditionKind.BinaryMechanismState
		)
		and (
			not isNonEmptyString(condition.objectId)
			or not isNonEmptyString(condition.expectedState)
		)
	then
		return false, "state condition requires objectId and expectedState"
	end
	if
		(
			kind == Types.ConditionKind.InteractionCompleted
			or kind == Types.ConditionKind.InspectionCompleted
		) and not isNonEmptyString(condition.referenceId)
	then
		return false, "interaction condition requires referenceId"
	end
	if
		kind == Types.ConditionKind.PresentationAcknowledged
		and not isNonEmptyString(condition.presentationId)
	then
		return false, "presentation condition requires presentationId"
	end
	return rejectUnsafe(condition)
end

function Validation.objective(objective: any): (boolean, string?)
	if type(objective) ~= "table" then
		return false, "objective must be a table"
	end
	for _, key in ipairs({ "objectiveId", "titleKey", "descriptionKey", "chapterId" }) do
		if not isNonEmptyString(objective[key]) then
			return false, key .. " is required"
		end
	end
	if type(objective.priority) ~= "number" then
		return false, "priority must be a number"
	end
	if type(objective.prerequisites) ~= "table" then
		return false, "prerequisites are required"
	end
	if not allowedPrerequisiteModes[objective.prerequisites.mode] then
		return false, "unsupported prerequisite mode"
	end
	local ok, reason = validateIdArray(
		objective.prerequisites.objectiveIds,
		Types.Limits.MaxPrerequisitesPerObjective,
		"prerequisites"
	)
	if not ok then
		return false, reason
	end
	ok, reason = validateIdArray(
		objective.nextObjectives,
		Types.Limits.MaxNextObjectivesPerObjective,
		"nextObjectives"
	)
	if not ok then
		return false, reason
	end
	ok, reason = validateIdArray(
		objective.optionalObjectives,
		Types.Limits.MaxOptionalObjectivesPerObjective,
		"optionalObjectives"
	)
	if not ok then
		return false, reason
	end
	if type(objective.completionConditions) ~= "table" or #objective.completionConditions == 0 then
		return false, "completionConditions are required"
	end
	if #objective.completionConditions > Types.Limits.MaxConditionsPerObjective then
		return false, "completionConditions exceed limit"
	end
	for _, condition in ipairs(objective.completionConditions) do
		ok, reason = Validation.condition(condition)
		if not ok then
			return false, reason
		end
	end
	if type(objective.failureConditions) ~= "table" then
		return false, "failureConditions must be an array"
	end
	for _, condition in ipairs(objective.failureConditions) do
		ok, reason = Validation.condition(condition)
		if not ok then
			return false, reason
		end
	end
	if type(objective.checkpointEligible) ~= "boolean" then
		return false, "checkpointEligible must be boolean"
	end
	if type(objective.tags) ~= "table" or #objective.tags > Types.Limits.MaxTags then
		return false, "tags must be a bounded array"
	end
	return rejectUnsafe(objective)
end

function Validation.stateName(value: any): boolean
	return type(value) == "string" and allowedObjectiveStates[value] == true
end

function Validation.event(event: any): (boolean, string?)
	if type(event) ~= "table" then
		return false, "event must be a table"
	end
	if not isNonEmptyString(event.eventId) then
		return false, "eventId is required"
	end
	if not isNonEmptyString(event.eventKind) then
		return false, "eventKind is required"
	end
	return rejectUnsafe(event)
end

function Validation.graph(objectives: { any }): (boolean, string?)
	if #objectives > Types.Limits.MaxObjectives then
		return false, "objective count exceeds limit"
	end
	local byId = {}
	for _, objective in ipairs(objectives) do
		local ok, reason = Validation.objective(objective)
		if not ok then
			return false, reason
		end
		if byId[objective.objectiveId] ~= nil then
			return false, "duplicate objective"
		end
		byId[objective.objectiveId] = objective
	end
	for _, objective in ipairs(objectives) do
		for _, objectiveId in ipairs(objective.prerequisites.objectiveIds) do
			if byId[objectiveId] == nil then
				return false, "missing prerequisite"
			end
		end
		for _, objectiveId in ipairs(objective.nextObjectives) do
			if byId[objectiveId] == nil then
				return false, "missing next objective"
			end
		end
		for _, objectiveId in ipairs(objective.optionalObjectives) do
			if byId[objectiveId] == nil then
				return false, "missing optional objective"
			end
		end
	end
	local visiting = {}
	local visited = {}
	local function visit(objectiveId: string, depth: number): (boolean, string?)
		if depth > Types.Limits.MaxGraphDepth then
			return false, "objective graph exceeds maximum depth"
		end
		if visiting[objectiveId] then
			return false, "cycle detected"
		end
		if visited[objectiveId] then
			return true, nil
		end
		visiting[objectiveId] = true
		local objective = byId[objectiveId]
		for _, nextId in ipairs(objective.nextObjectives) do
			local ok, reason = visit(nextId, depth + 1)
			if not ok then
				return false, reason
			end
		end
		visiting[objectiveId] = nil
		visited[objectiveId] = true
		return true, nil
	end
	for objectiveId in pairs(byId) do
		local ok, reason = visit(objectiveId, 1)
		if not ok then
			return false, reason
		end
	end
	return true, nil
end

return Validation

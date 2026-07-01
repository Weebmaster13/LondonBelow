--!strict

local ObjectiveValidator = {}

local allowedKinds = {
	Primary = true,
	Secondary = true,
	Hidden = true,
	Personal = true,
	Party = true,
	Branching = true,
	Timed = true,
}

function ObjectiveValidator.validateDefinition(definition: any): (boolean, string?)
	if type(definition.id) ~= "string" or definition.id == "" then
		return false, "objective id is required"
	end
	if not allowedKinds[definition.kind] then
		return false, "objective kind is unsupported"
	end
	if type(definition.displayName) ~= "string" or definition.displayName == "" then
		return false, "objective display name is required"
	end
	if type(definition.steps) ~= "table" or #definition.steps == 0 then
		return false, "objective requires at least one step"
	end
	return true, nil
end

function ObjectiveValidator.validateProgress(status: any, stepId: string): (boolean, string?)
	if status.started ~= true or status.completed == true or status.failed == true then
		return false, "objective is not progressable"
	end
	if type(stepId) ~= "string" or stepId == "" then
		return false, "objective step id is required"
	end
	return true, nil
end

function ObjectiveValidator.validate(): (boolean, string?)
	return true, nil
end

return ObjectiveValidator

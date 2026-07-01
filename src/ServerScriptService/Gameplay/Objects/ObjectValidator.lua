--!strict

local Types = require(script.Parent.ObjectTypes)

local ObjectValidator = {}

type ObjectDefinition = Types.ObjectDefinition

local allowedKinds = {}
for _, kind in ipairs(Types.AllowedKinds) do
	allowedKinds[kind] = true
end

local function contains(values: { string }, target: string): boolean
	for _, value in ipairs(values) do
		if value == target then
			return true
		end
	end
	return false
end

function ObjectValidator.validateDefinition(definition: ObjectDefinition): (boolean, string?)
	if type(definition.id) ~= "string" or definition.id == "" then
		return false, "object id is required"
	end
	if not allowedKinds[definition.kind] then
		return false, "object kind is not supported"
	end
	if type(definition.ownerSystem) ~= "string" or definition.ownerSystem == "" then
		return false, "object owner system is required"
	end
	if #definition.allowedStates == 0 then
		return false, "object must declare allowed states"
	end
	if not contains(definition.allowedStates, definition.initialState) then
		return false, "initial state must be allowed"
	end
	return true, nil
end

function ObjectValidator.validateState(
	definition: ObjectDefinition,
	nextState: string
): (boolean, string?)
	if not contains(definition.allowedStates, nextState) then
		return false, "object state is not allowed"
	end
	return true, nil
end

function ObjectValidator.validate(): (boolean, string?)
	return true, nil
end

return ObjectValidator

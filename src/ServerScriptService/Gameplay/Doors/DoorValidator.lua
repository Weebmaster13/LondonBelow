--!strict

local DoorStateMachine = require(script.Parent.DoorStateMachine)

local DoorValidator = {}

function DoorValidator.validateDefinition(definition: any): (boolean, string?)
	if type(definition.id) ~= "string" or definition.id == "" then
		return false, "door id is required"
	end
	if type(definition.displayName) ~= "string" or definition.displayName == "" then
		return false, "door display name is required"
	end
	if type(definition.initialState) ~= "string" then
		return false, "door initial state is required"
	end
	if not DoorStateMachine.isSupportedState(definition.initialState) then
		return false, "door initial state is unsupported"
	end
	return true, nil
end

function DoorValidator.validateTransition(fromState: string, toState: string): (boolean, string?)
	if not DoorStateMachine.canTransition(fromState, toState) then
		return false, "door transition is not allowed"
	end
	return true, nil
end

function DoorValidator.validate(): (boolean, string?)
	return true, nil
end

return DoorValidator

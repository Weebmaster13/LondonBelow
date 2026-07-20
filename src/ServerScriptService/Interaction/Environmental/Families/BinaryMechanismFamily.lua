--!strict

local Types = require(script.Parent.Parent.EnvironmentalTypes)

local BinaryMechanismFamily = {}

local VALID_STATES = {
	[Types.State.Open] = true,
	[Types.State.Closed] = true,
	[Types.State.On] = true,
	[Types.State.Off] = true,
	[Types.State.Active] = true,
	[Types.State.Disabled] = true,
}

local TRANSITIONS = {
	[Types.State.Closed] = {
		[Types.Action.Open] = Types.State.Open,
		[Types.Action.Toggle] = Types.State.Open,
	},
	[Types.State.Open] = {
		[Types.Action.Close] = Types.State.Closed,
		[Types.Action.Toggle] = Types.State.Closed,
	},
	[Types.State.Off] = {
		[Types.Action.Activate] = Types.State.On,
		[Types.Action.Toggle] = Types.State.On,
	},
	[Types.State.On] = {
		[Types.Action.Toggle] = Types.State.Off,
	},
}

function BinaryMechanismFamily.validateDefinition(definition: any): (boolean, string?)
	if VALID_STATES[definition.initialState] ~= true then
		return false, Types.ResultCode.EnvironmentStateInvalid
	end
	return true, nil
end

function BinaryMechanismFamily.evaluate(state: any, actionId: string)
	local nextState = if TRANSITIONS[state.currentState] ~= nil
		then TRANSITIONS[state.currentState][actionId]
		else nil
	if nextState == nil then
		return {
			ok = false,
			code = Types.ResultCode.EnvironmentTransitionInvalid,
		}
	end
	return {
		ok = true,
		actionId = actionId,
		nextState = nextState,
		presentation = {
			animationStateKey = string.lower(nextState),
			audioStateKey = string.lower(actionId),
			visualStateKey = string.lower(nextState),
		},
	}
end

return BinaryMechanismFamily

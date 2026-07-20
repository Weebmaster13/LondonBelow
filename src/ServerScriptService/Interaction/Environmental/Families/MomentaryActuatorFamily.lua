--!strict

local Types = require(script.Parent.Parent.EnvironmentalTypes)

local MomentaryActuatorFamily = {}

function MomentaryActuatorFamily.validateDefinition(definition: any): (boolean, string?)
	if
		definition.initialState ~= Types.State.Ready
		and definition.initialState ~= Types.State.Disabled
	then
		return false, Types.ResultCode.EnvironmentStateInvalid
	end
	return true, nil
end

function MomentaryActuatorFamily.evaluate(state: any, actionId: string, definition: any)
	if actionId ~= Types.Action.Activate then
		return { ok = false, code = Types.ResultCode.EnvironmentActionUnsupported }
	end
	if state.currentState ~= Types.State.Ready then
		return { ok = false, code = Types.ResultCode.EnvironmentTransitionInvalid }
	end
	if definition.dependency ~= nil and type(definition.dependency.targetObjectId) ~= "string" then
		return { ok = false, code = Types.ResultCode.EnvironmentDependencyMissing }
	end
	return {
		ok = true,
		actionId = actionId,
		nextState = Types.State.Cooldown,
		dependency = definition.dependency,
		presentation = {
			animationStateKey = "activated",
			audioStateKey = "activate",
			visualStateKey = "cooldown",
		},
	}
end

return MomentaryActuatorFamily

--!strict

local Types = require(script.Parent.Parent.EnvironmentalTypes)

local InspectableObjectFamily = {}

function InspectableObjectFamily.validateDefinition(definition: any): (boolean, string?)
	if
		definition.initialState ~= Types.State.Available
		and definition.initialState ~= Types.State.Inspected
	then
		return false, Types.ResultCode.EnvironmentStateInvalid
	end
	return true, nil
end

function InspectableObjectFamily.evaluate(state: any, actionId: string, definition: any)
	if actionId ~= Types.Action.Inspect then
		return { ok = false, code = Types.ResultCode.EnvironmentActionUnsupported }
	end
	if state.currentState == Types.State.Inspected and definition.repeatPolicy ~= "Repeatable" then
		return { ok = false, code = Types.ResultCode.EnvironmentAlreadyInspected }
	end
	return {
		ok = true,
		actionId = actionId,
		nextState = Types.State.Inspected,
		presentation = {
			presentationCategory = "Inspection",
			inspectionId = definition.presentationMetadata.inspectionId,
			titleKey = definition.presentationMetadata.titleKey,
			bodyKey = definition.presentationMetadata.bodyKey,
		},
	}
end

return InspectableObjectFamily

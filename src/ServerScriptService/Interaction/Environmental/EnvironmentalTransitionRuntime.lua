--!strict

local FamilyRegistry = require(script.Parent.EnvironmentalFamilyRegistry)
local Types = require(script.Parent.EnvironmentalTypes)

local TransitionRuntime = {}

local function supports(definition: any, actionId: string): boolean
	for _, supported in ipairs(definition.supportedActions) do
		if supported == actionId then
			return true
		end
	end
	return false
end

function TransitionRuntime.evaluate(definition: any, state: any, actionId: string)
	if definition == nil or state == nil then
		return { ok = false, code = Types.ResultCode.EnvironmentObjectNotFound }
	end
	if not state.enabled then
		return { ok = false, code = Types.ResultCode.EnvironmentObjectDisabled }
	end
	if not supports(definition, actionId) then
		return { ok = false, code = Types.ResultCode.EnvironmentActionUnsupported }
	end
	local family = FamilyRegistry.get(definition.family)
	if family == nil then
		return { ok = false, code = Types.ResultCode.EnvironmentFamilyNotFound }
	end
	local familyResult = family.evaluate(state, actionId, definition)
	if familyResult.ok ~= true then
		return familyResult
	end
	return {
		ok = true,
		objectId = definition.id,
		actionId = actionId,
		family = definition.family,
		previousState = state.currentState,
		nextState = familyResult.nextState,
		presentation = familyResult.presentation or {},
		dependency = familyResult.dependency,
		requiresSession = true,
		requiresContention = definition.contentionPolicy ~= "Shared",
		cooldownSeconds = if type(definition.cooldownPolicy) == "table"
			then definition.cooldownPolicy.seconds
			else nil,
	}
end

return TransitionRuntime

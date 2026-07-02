--!strict
-- Text key schema boundary. Text keys are identifiers, not final dialogue.

local LocalizationTextKeyRuntime = {}

function LocalizationTextKeyRuntime.register(state: any, schema: any): (boolean, string?)
	return state.registerTextKey(schema)
end

return LocalizationTextKeyRuntime

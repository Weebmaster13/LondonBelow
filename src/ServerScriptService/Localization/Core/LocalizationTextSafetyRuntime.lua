--!strict
-- Text safety schema boundary. Text safety rules are constraints, not moderation execution.

local LocalizationTextSafetyRuntime = {}

function LocalizationTextSafetyRuntime.register(state: any, schema: any): (boolean, string?)
	return state.registerTextSafety(schema)
end

return LocalizationTextSafetyRuntime

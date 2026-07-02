--!strict
-- Fallback policy schema boundary. Fallbacks are policies, not runtime execution.

local LocalizationFallbackRuntime = {}

function LocalizationFallbackRuntime.register(state: any, schema: any): (boolean, string?)
	return state.registerFallback(schema)
end

return LocalizationFallbackRuntime

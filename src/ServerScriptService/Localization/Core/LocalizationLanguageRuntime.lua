--!strict
-- Language schema boundary. Language records are schemas, not player locale execution.

local LocalizationLanguageRuntime = {}

function LocalizationLanguageRuntime.register(state: any, schema: any): (boolean, string?)
	return state.registerLanguage(schema)
end

return LocalizationLanguageRuntime

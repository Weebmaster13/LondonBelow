--!strict
-- Caption schema boundary. Captions are schemas, not rendered captions.

local LocalizationCaptionRuntime = {}

function LocalizationCaptionRuntime.register(state: any, schema: any): (boolean, string?)
	return state.registerCaption(schema)
end

return LocalizationCaptionRuntime

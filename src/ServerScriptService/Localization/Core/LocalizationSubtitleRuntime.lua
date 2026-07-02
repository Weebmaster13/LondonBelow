--!strict
-- Subtitle schema boundary. Subtitles are schemas, not rendered subtitles.

local LocalizationSubtitleRuntime = {}

function LocalizationSubtitleRuntime.register(state: any, schema: any): (boolean, string?)
	return state.registerSubtitle(schema)
end

return LocalizationSubtitleRuntime

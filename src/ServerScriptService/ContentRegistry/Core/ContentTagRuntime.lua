--!strict
-- Content tag schema boundary. Tags are metadata, not gameplay behavior.

local ContentTagRuntime = {}

function ContentTagRuntime.register(state: any, schema: any): (boolean, string?)
	return state.registerTag(schema)
end

return ContentTagRuntime

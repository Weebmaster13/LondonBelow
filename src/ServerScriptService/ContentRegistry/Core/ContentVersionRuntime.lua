--!strict
-- Content version schema boundary. Versions are compatibility records, not migrations.

local ContentVersionRuntime = {}

function ContentVersionRuntime.register(state: any, schema: any): (boolean, string?)
	return state.registerVersion(schema)
end

return ContentVersionRuntime

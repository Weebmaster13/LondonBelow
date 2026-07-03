--!strict
-- Content category schema boundary. Categories classify records and do not load content.

local ContentCategoryRuntime = {}

function ContentCategoryRuntime.register(state: any, schema: any): (boolean, string?)
	return state.registerCategory(schema)
end

return ContentCategoryRuntime

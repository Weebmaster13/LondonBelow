--!strict
-- Content dependency schema boundary. Dependencies are data, not load order execution.

local ContentDependencyRuntime = {}

function ContentDependencyRuntime.register(state: any, schema: any): (boolean, string?)
	return state.registerDependency(schema)
end

return ContentDependencyRuntime

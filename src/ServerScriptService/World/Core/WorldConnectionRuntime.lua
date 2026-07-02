--!strict
-- Traversal connection schema registration facade. No traversal execution occurs here.

local Runtime = {}

function Runtime.register(state: any, schema: any): (boolean, string?)
	return state.register("connections", schema)
end

return Runtime

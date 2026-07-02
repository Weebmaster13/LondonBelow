--!strict
-- Tool definitions are schema records only; they never execute tool behavior.

local Runtime = {}

function Runtime.register(state: any, schema: any): (boolean, string?)
	return state.registerTool(schema)
end

return Runtime

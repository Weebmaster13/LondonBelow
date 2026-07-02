--!strict
-- Command schemas are inert records; this runtime never executes commands.

local Runtime = {}

function Runtime.register(state: any, schema: any): (boolean, string?)
	return state.registerCommand(schema)
end

return Runtime

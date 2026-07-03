--!strict
-- Runtime node schema facade.

local Runtime = {}

function Runtime.register(state: any, schema: any): (boolean, string?)
	return state.registerNode(schema)
end

return Runtime

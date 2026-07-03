--!strict
-- Runtime ordering schema facade.

local Runtime = {}

function Runtime.register(state: any, schema: any): (boolean, string?)
	return state.registerOrdering(schema)
end

return Runtime

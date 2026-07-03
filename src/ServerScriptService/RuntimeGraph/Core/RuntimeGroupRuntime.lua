--!strict
-- Runtime group schema facade.

local Runtime = {}

function Runtime.register(state: any, schema: any): (boolean, string?)
	return state.registerGroup(schema)
end

return Runtime

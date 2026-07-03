--!strict
-- Runtime compatibility schema facade.

local Runtime = {}

function Runtime.register(state: any, schema: any): (boolean, string?)
	return state.registerCompatibility(schema)
end

return Runtime

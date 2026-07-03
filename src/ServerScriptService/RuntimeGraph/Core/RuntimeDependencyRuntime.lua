--!strict
-- Runtime dependency schema facade.

local Runtime = {}

function Runtime.register(state: any, schema: any): (boolean, string?)
	return state.registerDependency(schema)
end

return Runtime

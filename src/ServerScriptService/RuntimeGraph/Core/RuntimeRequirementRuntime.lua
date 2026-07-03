--!strict
-- Runtime requirement schema facade.

local Runtime = {}

function Runtime.register(state: any, schema: any): (boolean, string?)
	return state.registerRequirement(schema)
end

return Runtime

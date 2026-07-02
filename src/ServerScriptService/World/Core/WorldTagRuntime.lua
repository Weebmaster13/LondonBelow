--!strict
-- World tag schema facade.

local Runtime = {}

function Runtime.register(state: any, schema: any): (boolean, string?)
	return state.register("tags", schema)
end

return Runtime

--!strict
-- Zone schema registration facade.

local Runtime = {}

function Runtime.register(state: any, schema: any): (boolean, string?)
	return state.register("zones", schema)
end

return Runtime

--!strict
-- Region schema registration facade.

local Runtime = {}

function Runtime.register(state: any, schema: any): (boolean, string?)
	return state.register("regions", schema)
end

return Runtime

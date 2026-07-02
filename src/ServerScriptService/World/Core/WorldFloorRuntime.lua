--!strict
-- Floor schema registration facade.

local Runtime = {}

function Runtime.register(state: any, schema: any): (boolean, string?)
	return state.register("floors", schema)
end

return Runtime

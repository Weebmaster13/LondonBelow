--!strict
-- Building schema registration facade.

local Runtime = {}

function Runtime.register(state: any, schema: any): (boolean, string?)
	return state.register("buildings", schema)
end

return Runtime

--!strict
-- Room schema registration facade.

local Runtime = {}

function Runtime.register(state: any, schema: any): (boolean, string?)
	return state.register("rooms", schema)
end

return Runtime

--!strict
-- Environmental classification schema facade.

local Runtime = {}

function Runtime.register(state: any, schema: any): (boolean, string?)
	return state.register("classifications", schema)
end

return Runtime

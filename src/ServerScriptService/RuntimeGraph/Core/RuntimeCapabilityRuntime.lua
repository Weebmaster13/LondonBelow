--!strict
-- Runtime capability schema facade.

local Runtime = {}

function Runtime.register(state: any, schema: any): (boolean, string?)
	return state.registerCapability(schema)
end

return Runtime

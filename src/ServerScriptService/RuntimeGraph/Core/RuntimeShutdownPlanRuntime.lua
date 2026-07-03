--!strict
-- Runtime shutdown plan schema facade.

local Runtime = {}

function Runtime.register(state: any, schema: any): (boolean, string?)
	return state.registerShutdownPlan(schema)
end

return Runtime

--!strict
-- Runtime startup plan schema facade.

local Runtime = {}

function Runtime.register(state: any, schema: any): (boolean, string?)
	return state.registerStartupPlan(schema)
end

return Runtime

--!strict
local Runtime = {}
function Runtime.register(state: any, schema: any): (boolean, string?)
	return state.registerTransition(schema)
end
return Runtime

--!strict
local Runtime = {}
function Runtime.register(state: any, schema: any): (boolean, string?)
	return state.registerGuard(schema)
end
return Runtime

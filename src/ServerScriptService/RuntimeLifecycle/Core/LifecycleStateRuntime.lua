--!strict
local Runtime = {}
function Runtime.register(state: any, schema: any): (boolean, string?)
	return state.registerLifecycleState(schema)
end
return Runtime

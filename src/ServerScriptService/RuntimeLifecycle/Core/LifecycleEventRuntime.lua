--!strict
local Runtime = {}
function Runtime.register(state: any, schema: any): (boolean, string?)
	return state.registerEvent(schema)
end
return Runtime

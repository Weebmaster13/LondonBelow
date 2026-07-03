--!strict
local Runtime = {}
function Runtime.register(state: any, schema: any): (boolean, string?)
	return state.registerAudit(schema)
end
return Runtime

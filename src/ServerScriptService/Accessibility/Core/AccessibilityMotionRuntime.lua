--!strict
-- Motion comfort schemas describe future camera/motion safety boundaries only.

local Runtime = {}

function Runtime.register(state: any, schema: any): (boolean, string?)
	return state.registerMotion(schema)
end

return Runtime

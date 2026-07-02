--!strict
-- Save/load package schemas are records only; no persistence is performed.

local Runtime = {}

function Runtime.register(state: any, schema: any): (boolean, string?)
	return state.registerPackage(schema)
end

return Runtime

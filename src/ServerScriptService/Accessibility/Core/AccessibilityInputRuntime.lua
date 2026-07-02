--!strict
-- Input assist schemas are records only; no input remapping runs here.

local Runtime = {}

function Runtime.register(state: any, schema: any): (boolean, string?)
	return state.registerInput(schema)
end

return Runtime

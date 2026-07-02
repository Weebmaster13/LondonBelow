--!strict
-- Visual safety rules are inert records; no lighting or VFX changes run here.

local Runtime = {}

function Runtime.register(state: any, schema: any): (boolean, string?)
	return state.registerVisual(schema)
end

return Runtime

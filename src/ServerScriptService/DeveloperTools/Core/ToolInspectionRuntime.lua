--!strict
-- Inspection schemas describe future internal views only; no inspection is executed.

local Runtime = {}

function Runtime.register(state: any, schema: any): (boolean, string?)
	return state.registerInspection(schema)
end

return Runtime

--!strict
-- Report packages describe future developer reports only; no analytics collection runs here.

local Runtime = {}

function Runtime.register(state: any, schema: any): (boolean, string?)
	return state.registerReport(schema)
end

return Runtime

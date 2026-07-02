--!strict
-- Party session schemas are descriptive only and do not execute party gameplay.

local Runtime = {}

function Runtime.register(state: any, schema: any): (boolean, string?)
	return state.registerParty(schema)
end

return Runtime

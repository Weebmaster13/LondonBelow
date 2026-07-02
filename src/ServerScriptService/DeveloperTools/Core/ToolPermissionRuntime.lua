--!strict
-- Permission schemas describe future developer access boundaries without granting powers.

local Runtime = {}

function Runtime.register(state: any, schema: any): (boolean, string?)
	return state.registerPermission(schema)
end

return Runtime

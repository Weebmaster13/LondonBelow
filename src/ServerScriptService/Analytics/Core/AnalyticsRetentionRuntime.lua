--!strict
-- retention policy schemas describe future developer access boundaries without granting powers.

local Runtime = {}

function Runtime.register(state: any, schema: any): (boolean, string?)
	return state.registerRetention(schema)
end

return Runtime

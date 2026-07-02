--!strict
-- Accessibility setting schemas are records only; no client setting is applied here.

local Runtime = {}

function Runtime.register(state: any, schema: any): (boolean, string?)
	return state.registerSetting(schema)
end

return Runtime

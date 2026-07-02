--!strict
-- consent schemas describe future developer consents only; no analytics collection runs here.

local Runtime = {}

function Runtime.register(state: any, schema: any): (boolean, string?)
	return state.registerConsent(schema)
end

return Runtime

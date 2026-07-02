--!strict
-- Authority rule schema registration boundary. This does not approve live authority.

local SecurityAuthorityRuntime = {}

function SecurityAuthorityRuntime.register(state: any, schema: any): (boolean, string?)
	return state.registerAuthorityRule(schema)
end

return SecurityAuthorityRuntime

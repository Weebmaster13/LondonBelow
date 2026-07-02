--!strict
-- Remote safety contract boundary. Contracts are schemas and do not create remotes.

local SecurityRemoteSafetyRuntime = {}

function SecurityRemoteSafetyRuntime.register(state: any, schema: any): (boolean, string?)
	return state.registerRemoteSafety(schema)
end

return SecurityRemoteSafetyRuntime

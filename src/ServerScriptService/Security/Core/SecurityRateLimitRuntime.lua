--!strict
-- Rate-limit policy schema boundary. Policies are not automatic throttles.

local SecurityRateLimitRuntime = {}

function SecurityRateLimitRuntime.register(state: any, schema: any): (boolean, string?)
	return state.registerRateLimit(schema)
end

return SecurityRateLimitRuntime

--!strict
-- Trust policy schema registration boundary. This records policy data only.

local SecurityTrustPolicyRuntime = {}

function SecurityTrustPolicyRuntime.register(state: any, schema: any): (boolean, string?)
	return state.registerTrustPolicy(schema)
end

return SecurityTrustPolicyRuntime

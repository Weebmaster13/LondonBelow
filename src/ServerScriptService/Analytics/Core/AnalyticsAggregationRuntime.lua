--!strict
-- aggregation schemas are inert records; this runtime never executes aggregations.

local Runtime = {}

function Runtime.register(state: any, schema: any): (boolean, string?)
	return state.registerAggregation(schema)
end

return Runtime

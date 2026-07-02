--!strict
-- Metric definitions describe future measurements only; no metrics are collected here.

local Runtime = {}

function Runtime.register(state: any, schema: any): (boolean, string?)
	return state.registerMetric(schema)
end

return Runtime

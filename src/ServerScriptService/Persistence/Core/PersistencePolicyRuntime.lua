--!strict
-- Write and retry policy schemas describe future persistence rules only.

local Runtime = {}

function Runtime.registerWritePolicy(state: any, schema: any): (boolean, string?)
	return state.registerWritePolicy(schema)
end

function Runtime.registerRetryPolicy(state: any, schema: any): (boolean, string?)
	return state.registerRetryPolicy(schema)
end

return Runtime

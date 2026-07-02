--!strict
-- Runtime category schema boundary for future performance budget grouping.

local PerformanceCategoryRuntime = {}

function PerformanceCategoryRuntime.register(state: any, schema: any): (boolean, string?)
	return state.registerCategory(schema)
end

return PerformanceCategoryRuntime

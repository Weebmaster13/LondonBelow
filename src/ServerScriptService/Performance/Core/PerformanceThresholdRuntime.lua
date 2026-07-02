--!strict
-- Warning threshold schema boundary for future budget reports.

local PerformanceThresholdRuntime = {}

function PerformanceThresholdRuntime.register(state: any, schema: any): (boolean, string?)
	return state.registerThreshold(schema)
end

return PerformanceThresholdRuntime

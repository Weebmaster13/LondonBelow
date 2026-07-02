--!strict
-- Report schema boundary. This records future report shapes only and does not collect measurements.

local PerformanceReportRuntime = {}

function PerformanceReportRuntime.record(state: any, record: any): (boolean, string?)
	return state.registerReport(record)
end

return PerformanceReportRuntime

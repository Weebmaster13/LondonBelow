--!strict
-- Readiness schemas record server-owned readiness data only.

local Runtime = {}

function Runtime.record(state: any, record: any): (boolean, string?)
	return state.recordReadiness(record)
end

return Runtime

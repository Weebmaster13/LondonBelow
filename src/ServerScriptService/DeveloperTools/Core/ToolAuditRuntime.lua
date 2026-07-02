--!strict
-- Audit records are inert schema records; this runtime does not moderate or execute tools.

local Runtime = {}

function Runtime.record(state: any, record: any): (boolean, string?)
	return state.recordAudit(record)
end

return Runtime

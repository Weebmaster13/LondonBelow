--!strict
-- Security audit record schema boundary. Audit records are inert and not moderation logs.

local SecurityAuditRuntime = {}

function SecurityAuditRuntime.record(state: any, record: any): (boolean, string?)
	return state.registerAudit(record)
end

return SecurityAuditRuntime

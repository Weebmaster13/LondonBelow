--!strict
-- report schemas are inert schema records; this runtime does not moderate or execute events.

local Runtime = {}

function Runtime.record(state: any, record: any): (boolean, string?)
	return state.registerReport(record)
end

return Runtime

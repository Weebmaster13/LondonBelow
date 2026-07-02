--!strict
-- Progress record boundary. Progress is recorded as schema data only.

local Runtime = {}

function Runtime.record(state: any, record: any): (boolean, string?)
	return state.recordProgress(record)
end

return Runtime

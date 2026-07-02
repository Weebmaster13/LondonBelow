--!strict
-- Failure records are diagnostic records only; they do not retry or mutate saves.

local Runtime = {}

function Runtime.record(state: any, record: any): (boolean, string?)
	return state.recordFailure(record)
end

return Runtime

--!strict
-- Readability schemas are inert records; no UI or text scaling is applied here.

local Runtime = {}

function Runtime.record(state: any, record: any): (boolean, string?)
	return state.registerReadability(record)
end

return Runtime

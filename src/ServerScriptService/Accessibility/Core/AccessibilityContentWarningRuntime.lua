--!strict
-- Content warning schemas are inert records; no UI or presentation is shown here.

local Runtime = {}

function Runtime.register(state: any, record: any): (boolean, string?)
	return state.registerContentWarning(record)
end

return Runtime

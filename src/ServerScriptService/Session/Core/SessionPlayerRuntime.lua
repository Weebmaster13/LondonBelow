--!strict
-- Player session records are schema records only, not player spawning or movement.

local Runtime = {}

function Runtime.register(state: any, record: any): (boolean, string?)
	return state.registerPlayerSession(record)
end

return Runtime

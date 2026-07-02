--!strict
-- Lifecycle schemas describe session state without matchmaking or teleport execution.

local Runtime = {}

function Runtime.recordLifecycle(state: any, record: any): (boolean, string?)
	return state.recordLifecycle(record)
end

function Runtime.recordJoinLeave(state: any, record: any): (boolean, string?)
	return state.recordJoinLeave(record)
end

return Runtime

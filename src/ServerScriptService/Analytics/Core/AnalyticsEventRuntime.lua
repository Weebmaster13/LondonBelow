--!strict
-- Analytics event schemas are records only; they never collect or send telemetry.

local Runtime = {}

function Runtime.register(state: any, schema: any): (boolean, string?)
	return state.registerEvent(schema)
end

return Runtime

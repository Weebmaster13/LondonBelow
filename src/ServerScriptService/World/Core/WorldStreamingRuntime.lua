--!strict
-- Streaming region schema facade. This records streaming intent only and never streams rooms.

local Runtime = {}

function Runtime.register(state: any, schema: any): (boolean, string?)
	return state.register("streamingRegions", schema)
end

return Runtime

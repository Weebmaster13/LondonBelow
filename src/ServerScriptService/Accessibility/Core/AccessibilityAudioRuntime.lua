--!strict
-- Audio safety rules are inert records; no sound playback or mixing is executed here.

local Runtime = {}

function Runtime.register(state: any, schema: any): (boolean, string?)
	return state.registerAudio(schema)
end

return Runtime

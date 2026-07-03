--!strict
-- Content reference schema boundary. References are schema links, not runtime objects.

local ContentReferenceRuntime = {}

function ContentReferenceRuntime.register(state: any, schema: any): (boolean, string?)
	return state.registerReference(schema)
end

return ContentReferenceRuntime

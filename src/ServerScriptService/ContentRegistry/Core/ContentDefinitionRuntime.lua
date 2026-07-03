--!strict
-- Content definition schema boundary. Definitions are registry records, not real content.

local ContentDefinitionRuntime = {}

function ContentDefinitionRuntime.register(state: any, schema: any): (boolean, string?)
	return state.registerContentDefinition(schema)
end

return ContentDefinitionRuntime

--!strict
-- Migration schemas are descriptive only and never execute migrations.

local Runtime = {}

function Runtime.register(state: any, schema: any): (boolean, string?)
	return state.registerMigration(schema)
end

return Runtime

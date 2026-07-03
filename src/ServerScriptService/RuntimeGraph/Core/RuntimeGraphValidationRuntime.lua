--!strict
-- Runtime graph validation record schema facade.

local Runtime = {}

function Runtime.register(state: any, schema: any): (boolean, string?)
	return state.registerValidationRecord(schema)
end

return Runtime

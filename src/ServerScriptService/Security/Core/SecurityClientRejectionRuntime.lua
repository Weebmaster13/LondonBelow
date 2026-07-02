--!strict
-- Client rejection category boundary. Categories are not punishments.

local SecurityClientRejectionRuntime = {}

function SecurityClientRejectionRuntime.register(state: any, schema: any): (boolean, string?)
	return state.registerClientRejection(schema)
end

return SecurityClientRejectionRuntime

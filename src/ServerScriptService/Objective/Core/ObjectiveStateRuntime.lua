--!strict
-- Objective state schema validation helper. State schemas do not complete objectives.

local Validation = require(script.Parent.ObjectiveValidation)

local Runtime = {}

function Runtime.validate(state: any): (boolean, string?)
	return Validation.state(state)
end

return Runtime

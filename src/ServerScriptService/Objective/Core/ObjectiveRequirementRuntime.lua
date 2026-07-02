--!strict
-- Requirement schema validation helper. Requirements do not execute gameplay.

local Validation = require(script.Parent.ObjectiveValidation)

local Runtime = {}

function Runtime.validate(requirements: any): (boolean, string?)
	return Validation.requirements(requirements)
end

return Runtime

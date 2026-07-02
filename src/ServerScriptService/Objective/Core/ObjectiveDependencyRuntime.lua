--!strict
-- Dependency schema validation helper. Dependencies are schema relationships only.

local Validation = require(script.Parent.ObjectiveValidation)

local Runtime = {}

function Runtime.validate(dependencies: any): (boolean, string?)
	return Validation.dependencies(dependencies)
end

return Runtime

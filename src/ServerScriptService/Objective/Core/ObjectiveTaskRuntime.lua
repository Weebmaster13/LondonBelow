--!strict
-- Task schema validation helper. Tasks are descriptive and never complete objectives.

local Validation = require(script.Parent.ObjectiveValidation)

local Runtime = {}

function Runtime.validate(tasks: any): (boolean, string?)
	return Validation.tasks(tasks)
end

return Runtime

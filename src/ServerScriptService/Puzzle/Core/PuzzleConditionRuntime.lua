--!strict
-- Puzzle condition schema validation helpers.

local Validation = require(script.Parent.PuzzleValidation)

local Conditions = {}

function Conditions.validate(conditions: any): (boolean, string?)
	return Validation.conditions(conditions)
end

return Conditions
